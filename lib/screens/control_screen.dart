import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart' as sensors;

import '../controllers/keyboard_controller.dart';
import '../controllers/mouse_controller.dart';
import '../models/connection_info.dart';
import '../services/connection_manager.dart';
import '../services/tcp_service.dart';
import '../services/udp_service.dart';
import '../services/websocket_service.dart';
import 'connection_screen.dart';

class ControlScreen extends StatefulWidget {
  final TcpService tcpService;
  final ConnectionInfo connection;

  const ControlScreen({
    super.key,
    required this.tcpService,
    required this.connection,
  });

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen>
    with WidgetsBindingObserver {
  late final UdpService udp;
  late final WebSocketService webSocket;
  late final MouseController mouseController;
  late final KeyboardController keyboardController;

  final TextEditingController _textInputController = TextEditingController();

  bool _gyroModeEnabled = false;
  bool _isStreaming = false;
  bool _showMouseTab = true;
  bool _useWebSocket = true; // Default to WebSocket
  bool _isFullscreen = false;
  Offset? _touchPosition; // Track touch position on trackpad
  Uint8List? _currentFrame;
  StreamSubscription<sensors.GyroscopeEvent>? _gyroSub;
  StreamSubscription<Uint8List>? _frameSub;
  StreamSubscription<ConnectionStatus>? _tcpStatusSub;
  StreamSubscription<WebSocketStatus>? _wsStatusSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Store active connection in the manager
    ConnectionManager().setActiveConnection(
      widget.tcpService,
      widget.connection,
    );

    udp = UdpService();
    webSocket = WebSocketService();
    mouseController = MouseController(widget.tcpService);
    keyboardController = KeyboardController(widget.tcpService);

    // Listen for TCP status changes
    _tcpStatusSub = widget.tcpService.statusStream.listen((status) {
      if (status == ConnectionStatus.disconnected ||
          status == ConnectionStatus.error) {
        if (_gyroModeEnabled) {
          _toggleGyroMode(false);
        }
        if (_isStreaming) {
          _stopStreaming();
        }
        if (mounted) {
          // Clear active connection
          ConnectionManager().clearActiveConnection();

          // Schedule navigation after the current frame to avoid Navigator lock
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const ConnectionScreen(),
                ),
                (route) => false,
              );
            }
          });
        }
      }
    });

    // Listen for WebSocket status changes
    _wsStatusSub = webSocket.statusStream.listen((status) {
      if (status == WebSocketStatus.error && _isStreaming && _useWebSocket) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('WebSocket connection lost')),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gyroSub?.cancel();
    _frameSub?.cancel();
    _tcpStatusSub?.cancel();
    _wsStatusSub?.cancel();
    _textInputController.dispose();

    // Clear active connection when leaving control screen
    ConnectionManager().clearActiveConnection();

    widget.tcpService.disconnect();
    udp.dispose();
    webSocket.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Disconnect when app is closed or paused
    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.paused) {
      widget.tcpService.disconnect();
      if (_isStreaming) {
        _stopStreaming();
      }
    }
  }

  void _toggleGyroMode(bool value) {
    if (value) {
      _gyroSub?.cancel();
      _gyroSub = sensors.gyroscopeEventStream().listen((
        sensors.GyroscopeEvent event,
      ) {
        mouseController.sendMovement(event.x, event.y);
      });
    } else {
      _gyroSub?.cancel();
      _gyroSub = null;
    }

    setState(() {
      _gyroModeEnabled = value;
    });
  }

  /// Waits for the desktop's response to a WebSocket start request. The
  /// desktop reports back the port it actually bound (it falls back to
  /// another port if the requested one was unavailable, e.g. taken by
  /// another app), so the client connects to whatever port comes back here
  /// rather than assuming [requestedPort] worked. Falls back to
  /// [requestedPort] if no response arrives in time, so older desktop
  /// builds that don't send a response still work as before.
  Future<int?> _awaitWebSocketStartPort(int requestedPort) async {
    final completer = Completer<int?>();
    late final StreamSubscription<Map<String, dynamic>> sub;
    sub = widget.tcpService.messageStream.listen((message) {
      final ws = message['websocket'];
      if (ws is! Map) return;
      switch (ws['status']) {
        case 'started':
          final port = ws['port'];
          if (port is int && !completer.isCompleted) {
            completer.complete(port);
          }
          break;
        case 'error':
          if (!completer.isCompleted) completer.complete(null);
          break;
      }
    });

    final result = await completer.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () => requestedPort,
    );
    await sub.cancel();
    return result;
  }

  Future<void> _startStreaming() async {
    if (_isStreaming) return;

    if (_useWebSocket) {
      // Use WebSocket streaming
      final requestedPort = 8080; // Preferred port; desktop may fall back to another
      final desktopIp = widget.connection.host;

      // Request server to start WebSocket streaming
      mouseController.startWebSocketStream(
        port: requestedPort,
        fps: 12,
        maxWidth: 1280,
        quality: 0.7,
      );

      // Wait for the desktop to report which port it actually bound to -- it
      // falls back to another port if the requested one is already in use,
      // so the client must not assume the requested port was honored.
      final wsPort = await _awaitWebSocketStartPort(requestedPort);
      if (wsPort == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to start WebSocket stream on desktop'),
            ),
          );
        }
        return;
      }

      // Connect to WebSocket
      final wsUrl = 'ws://$desktopIp:$wsPort';
      final success = await webSocket.connect(wsUrl);

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to connect to WebSocket stream'),
            ),
          );
        }
        return;
      }

      // Subscribe to frame stream
      _frameSub = webSocket.frameStream.listen((frame) {
        setState(() {
          _currentFrame = frame;
        });
      });

      setState(() {
        _isStreaming = true;
      });
    } else {
      // Use UDP streaming (existing implementation)
      final port = widget.connection.udpPort;

      // Start UDP listener
      final success = await udp.startListening(port);
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to start UDP listener')),
          );
        }
        return;
      }

      // Request server to start streaming
      mouseController.startScreenStream(
        port: port,
        fps: 12,
        maxWidth: 1280,
        quality: 0.7,
      );

      // Subscribe to frame stream
      _frameSub = udp.frameStream.listen((frame) {
        setState(() {
          _currentFrame = frame;
        });
      });

      setState(() {
        _isStreaming = true;
      });
    }
  }

  void _stopStreaming() {
    if (!_isStreaming) return;

    if (_useWebSocket) {
      // Stop WebSocket streaming
      mouseController.stopWebSocketStream();
      webSocket.disconnect();
    } else {
      // Stop UDP streaming
      mouseController.stopScreenStream();
      udp.stop();
    }

    _frameSub?.cancel();
    _frameSub = null;

    setState(() {
      _isStreaming = false;
      _currentFrame = null;
    });
  }

  void _handlePadUpdate(DragUpdateDetails details) {
    mouseController.sendMovement(details.delta.dx, details.delta.dy);
    setState(() {
      _touchPosition = details.localPosition;
    });
  }

  void _handlePadEnd(DragEndDetails details) {
    setState(() {
      _touchPosition = null;
    });
  }

  void _handleLeftClick() {
    mouseController.sendLeftClick();
  }

  void _handleRightClick() {
    mouseController.sendRightClick();
  }

  void _sendText() {
    final text = _textInputController.text;
    if (text.isNotEmpty) {
      keyboardController.typeText(text);
      _textInputController.clear();
    }
  }

  void _tapKey(String keyName) {
    keyboardController.tapNamedKey(keyName);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Show fullscreen streaming view
    if (_isFullscreen) {
      return PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (!didPop) {
            setState(() {
              _isFullscreen = false;
            });
          }
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Fullscreen streaming view
              Center(
                child: _currentFrame != null
                    ? InteractiveViewer(
                        panEnabled: true,
                        minScale: 0.5,
                        maxScale: 3.0,
                        child: Image.memory(
                          _currentFrame!,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isStreaming) ...[
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Waiting for frames...',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ] else ...[
                            Icon(
                              Icons.screen_share_outlined,
                              size: 64,
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Start streaming to view desktop',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ],
                      ),
              ),
              // Exit fullscreen button (top-right)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.fullscreen_exit),
                  color: Colors.white,
                  iconSize: 32,
                  onPressed: () {
                    setState(() {
                      _isFullscreen = false;
                    });
                  },
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.connection.nickname),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary,
                Color.lerp(colorScheme.primary, const Color(0xFF312E81), 0.35)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Disconnect',
            onPressed: () {
              ConnectionManager().clearActiveConnection();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const ConnectionScreen(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(flex: 40, child: _buildStreamingSection(colorScheme)),
          Expanded(
            flex: 60,
            child: Column(
              children: [
                Material(
                  color: colorScheme.surface,
                  elevation: 1,
                  shadowColor: Colors.black26,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(
                          value: true,
                          label: Text('Mouse'),
                          icon: Icon(Icons.mouse_rounded, size: 18),
                        ),
                        ButtonSegment<bool>(
                          value: false,
                          label: Text('Keyboard'),
                          icon: Icon(Icons.keyboard_rounded, size: 18),
                        ),
                      ],
                      selected: {_showMouseTab},
                      onSelectionChanged: (Set<bool> next) {
                        setState(() => _showMouseTab = next.first);
                      },
                      showSelectedIcon: false,
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        padding: WidgetStateProperty.all(
                          const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ColoredBox(
                    color: colorScheme.surfaceContainerLowest,
                    child: _showMouseTab
                        ? _buildMouseTab(colorScheme)
                        : _buildKeyboardTab(colorScheme),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamingSection(ColorScheme colorScheme) {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh.withOpacity(0.95),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.5),
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _isStreaming
                        ? 'Live · ${_useWebSocket ? 'WebSocket' : 'UDP'}'
                        : 'Stream idle',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                  ),
                ),
                // Fullscreen button
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  onPressed: () {
                    setState(() {
                      _isFullscreen = true;
                    });
                  },
                  tooltip: 'Fullscreen',
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isStreaming ? _stopStreaming : _startStreaming,
                  icon: Icon(_isStreaming ? Icons.stop : Icons.play_arrow),
                  label: Text(_isStreaming ? 'Stop' : 'Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isStreaming
                        ? Colors.red
                        : colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Screen preview
          Expanded(
            child: _currentFrame != null
                ? InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: Center(
                      child: Image.memory(
                        _currentFrame!,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      ),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isStreaming) ...[
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Waiting for frames...',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ] else ...[
                          Icon(
                            Icons.screen_share_outlined,
                            size: 64,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Start streaming to view desktop',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMouseTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: SwitchListTile.adaptive(
              value: _gyroModeEnabled,
              onChanged: _toggleGyroMode,
              title: const Text('Gyroscope control'),
              subtitle: const Text('Use device motion as pointer input'),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Touchpad Surface',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onPanUpdate: _handlePadUpdate,
            onPanEnd: _handlePadEnd,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colorScheme.primary, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    offset: Offset(0, 8),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Text(
                      'Swipe here to move cursor',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 16),
                    ),
                  ),
                  // Touch indicator
                  if (_touchPosition != null)
                    Positioned(
                      left: _touchPosition!.dx - 15,
                      top: _touchPosition!.dy - 15,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primary.withOpacity(0.3),
                          border: Border.all(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _handleLeftClick,
                  icon: const Icon(Icons.mouse),
                  label: const Text('Left Click'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _handleRightClick,
                  icon: const Icon(Icons.mouse_outlined),
                  label: const Text('Right Click'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboardTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Type Text',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textInputController,
                          decoration: const InputDecoration(
                            hintText: 'Enter text to type...',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onSubmitted: (_) => _sendText(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _sendText,
                        child: const Text('Send'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Quick Keys',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildKeyGrid([
            ('Enter', 'enter'),
            ('Backspace', 'backspace'),
            ('Tab', 'tab'),
            ('Escape', 'escape'),
            ('Space', 'space'),
            ('Delete', 'delete'),
          ]),
          const SizedBox(height: 16),
          Text(
            'Modifiers',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildKeyGrid([
            ('Ctrl', 'control'),
            ('Shift', 'shift'),
            ('Alt', 'alt'),
            ('Win', 'meta'),
          ]),
          const SizedBox(height: 16),
          Text(
            'Arrow Keys',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildKeyGrid([
            ('←', 'left'),
            ('↑', 'up'),
            ('↓', 'down'),
            ('→', 'right'),
          ]),
          const SizedBox(height: 16),
          Text(
            'Navigation',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildKeyGrid([
            ('Home', 'home'),
            ('End', 'end'),
            ('PgUp', 'pageup'),
            ('PgDn', 'pagedown'),
          ]),
        ],
      ),
    );
  }

  Widget _buildKeyGrid(List<(String, String)> keys) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: keys.map((key) {
        return ElevatedButton(
          onPressed: () => _tapKey(key.$2),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(key.$1),
        );
      }).toList(),
    );
  }
}
