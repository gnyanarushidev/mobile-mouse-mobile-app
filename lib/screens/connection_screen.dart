import 'dart:async';

import 'package:flutter/material.dart';

import '../models/connection_info.dart';
import '../services/connection_manager.dart';
import '../services/connection_storage.dart';
import '../services/tcp_service.dart';
import 'control_screen.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final _storage = ConnectionStorage();
  final _hostController = TextEditingController();
  final _tcpPortController = TextEditingController(text: '5000');
  final _udpPortController = TextEditingController(text: '6000');
  final _nicknameController = TextEditingController();

  List<ConnectionInfo> _savedConnections = [];
  bool _isConnecting = false;
  bool _showNewConnectionForm = false;

  @override
  void initState() {
    super.initState();
    _loadConnections();
    _checkExistingConnection();
  }

  void _checkExistingConnection() {
    // Check if there's an active connection and navigate to control screen
    final manager = ConnectionManager();
    if (manager.hasActiveConnection) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ControlScreen(
                tcpService: manager.activeTcpService!,
                connection: manager.activeConnection!,
              ),
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _hostController.dispose();
    _tcpPortController.dispose();
    _udpPortController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _loadConnections() async {
    final connections = await _storage.getConnections();
    setState(() {
      _savedConnections = connections;
    });
  }

  Future<void> _connectToDesktop(ConnectionInfo connection) async {
    setState(() => _isConnecting = true);

    try {
      final tcp = TcpService();
      final success = await tcp.connect(
        connection.host,
        connection.tcpPort,
        timeout: const Duration(seconds: 5),
      );

      if (!mounted) return;

      if (success) {
        // Update last used time and save
        final updatedConnection = connection.copyWith(lastUsed: DateTime.now());
        await _storage.saveConnection(updatedConnection);

        // Navigate to control screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                ControlScreen(tcpService: tcp, connection: updatedConnection),
          ),
        );
      } else {
        _showError('Connection failed. Check IP and port.');
      }
    } catch (e) {
      if (mounted) {
        _showError('Connection error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  Future<void> _connectWithNewConnection() async {
    final host = _hostController.text.trim();
    final tcpPort = int.tryParse(_tcpPortController.text.trim()) ?? 5000;
    final udpPort = int.tryParse(_udpPortController.text.trim()) ?? 6000;
    final nickname = _nicknameController.text.trim().isEmpty
        ? host
        : _nicknameController.text.trim();

    if (host.isEmpty) {
      _showError('Please enter a host IP address');
      return;
    }

    final connection = ConnectionInfo(
      host: host,
      tcpPort: tcpPort,
      udpPort: udpPort,
      nickname: nickname,
      lastUsed: DateTime.now(),
    );

    await _connectToDesktop(connection);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  Future<void> _deleteConnection(ConnectionInfo connection) async {
    await _storage.deleteConnection(connection);
    await _loadConnections();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${connection.nickname} deleted')));
    }
  }

  Future<void> _showEditDialog(ConnectionInfo connection) async {
    final hostCtrl = TextEditingController(text: connection.host);
    final tcpPortCtrl = TextEditingController(text: connection.tcpPort.toString());
    final udpPortCtrl = TextEditingController(text: connection.udpPort.toString());
    final nicknameCtrl = TextEditingController(text: connection.nickname);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Connection'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nicknameCtrl,
                decoration: const InputDecoration(
                  labelText: 'System Name',
                  prefixIcon: Icon(Icons.label),
                  hintText: 'My Desktop',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: hostCtrl,
                decoration: const InputDecoration(
                  labelText: 'Desktop IP',
                  prefixIcon: Icon(Icons.computer),
                  hintText: '192.168.1.100',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: tcpPortCtrl,
                      decoration: const InputDecoration(
                        labelText: 'TCP Port',
                        prefixIcon: Icon(Icons.settings_input_hdmi),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: udpPortCtrl,
                      decoration: const InputDecoration(
                        labelText: 'UDP Port',
                        prefixIcon: Icon(Icons.router),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final host = hostCtrl.text.trim();
              final tcpPort = int.tryParse(tcpPortCtrl.text.trim()) ?? 5000;
              final udpPort = int.tryParse(udpPortCtrl.text.trim()) ?? 6000;
              final nickname = nicknameCtrl.text.trim().isEmpty
                  ? host
                  : nicknameCtrl.text.trim();

              if (host.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Please enter a host IP address')),
                );
                return;
              }

              final updated = connection.copyWith(
                host: host,
                tcpPort: tcpPort,
                udpPort: udpPort,
                nickname: nickname,
              );

              _storage.updateConnection(connection, updated).then((_) {
                _loadConnections();
                if (mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('${updated.nickname} updated')),
                  );
                }
                Navigator.of(ctx).pop();
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    hostCtrl.dispose();
    tcpPortCtrl.dispose();
    udpPortCtrl.dispose();
    nicknameCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onGradient = Colors.white.withOpacity(0.88);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF020617),
              Color(0xFF1E1B4B),
              Color(0xFF4338CA),
            ],
            stops: [0.0, 0.42, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.2),
                                Colors.white.withOpacity(0.06),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.28),
                            ),
                          ),
                          child: Image.asset(
                            'assets/icon/icon.png',
                            height: 52,
                            width: 52,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mobile Mouse',
                                style: TextStyle(
                                  color: onGradient,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Connect to your desktop on the same Wi‑Fi',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.72),
                                  fontSize: 14,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 24,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: _isConnecting
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 52,
                                  height: 52,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Connecting…',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Checking TCP reachability',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FilledButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _showNewConnectionForm =
                                        !_showNewConnectionForm;
                                  });
                                },
                                icon: Icon(
                                  _showNewConnectionForm
                                      ? Icons.close_rounded
                                      : Icons.add_rounded,
                                ),
                                label: Text(
                                  _showNewConnectionForm
                                      ? 'Close form'
                                      : 'New connection',
                                ),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              ),

                              if (_showNewConnectionForm) ...[
                                const SizedBox(height: 20),
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.link_rounded,
                                              color: colorScheme.primary,
                                              size: 22,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Add desktop',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: -0.3,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Use your computer’s LAN IP (often 192.168.x.x).',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                        const SizedBox(height: 20),
                                        TextField(
                                          controller: _nicknameController,
                                          decoration: const InputDecoration(
                                            labelText: 'Nickname (optional)',
                                            prefixIcon: Icon(Icons.label),
                                            hintText: 'My Desktop',
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        TextField(
                                          controller: _hostController,
                                          decoration: const InputDecoration(
                                            labelText: 'Desktop IP',
                                            prefixIcon: Icon(Icons.computer),
                                            hintText: '192.168.1.100',
                                          ),
                                          keyboardType: TextInputType.number,
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: _tcpPortController,
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: 'TCP Port',
                                                      prefixIcon: Icon(
                                                        Icons
                                                            .settings_input_hdmi,
                                                      ),
                                                    ),
                                                keyboardType:
                                                    TextInputType.number,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: TextField(
                                                controller: _udpPortController,
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: 'UDP Port',
                                                      prefixIcon: Icon(
                                                        Icons.router,
                                                      ),
                                                    ),
                                                keyboardType:
                                                    TextInputType.number,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        FilledButton(
                                          onPressed: _connectWithNewConnection,
                                          child: const Text('Connect'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],

                              if (_savedConnections.isNotEmpty) ...[
                                const SizedBox(height: 28),
                                Row(
                                  children: [
                                    Text(
                                      'Recent',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.2,
                                          ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer
                                            .withOpacity(0.65),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${_savedConnections.length}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                ..._savedConnections.map((connection) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () =>
                                            _connectToDesktop(connection),
                                        borderRadius: BorderRadius.circular(20),
                                        child: Ink(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: colorScheme.outlineVariant
                                                  .withOpacity(0.6),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.04),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 14,
                                            ),
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 24,
                                                  backgroundColor: colorScheme
                                                      .primaryContainer
                                                      .withOpacity(0.85),
                                                  child: Icon(
                                                    Icons.desktop_mac_rounded,
                                                    color: colorScheme.primary,
                                                    size: 24,
                                                  ),
                                                ),
                                                const SizedBox(width: 14),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        connection.nickname,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Wrap(
                                                        spacing: 8,
                                                        runSpacing: 6,
                                                        children: [
                                                          _PortChip(
                                                            label:
                                                                'TCP ${connection.tcpPort}',
                                                            icon: Icons
                                                                .settings_input_hdmi,
                                                            colorScheme:
                                                                colorScheme,
                                                          ),
                                                          _PortChip(
                                                            label:
                                                                'UDP ${connection.udpPort}',
                                                            icon: Icons
                                                                .sensors_rounded,
                                                            colorScheme:
                                                                colorScheme,
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        connection.host,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                              color: colorScheme
                                                                  .onSurfaceVariant,
                                                              fontFeatures: const [
                                                                FontFeature
                                                                    .tabularFigures(),
                                                              ],
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                 IconButton(
                                                   icon: Icon(
                                                     Icons.edit_rounded,
                                                     color: colorScheme.primary.withOpacity(0.85),
                                                   ),
                                                   onPressed: () => _showEditDialog(connection),
                                                 ),
                                                 IconButton(
                                                   icon: Icon(
                                                     Icons.delete_outline_rounded,
                                                     color: colorScheme.error.withOpacity(0.85),
                                                   ),
                                                   onPressed: () => _deleteConnection(connection),
                                                  ),
                                               ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ] else if (!_showNewConnectionForm) ...[
                                const SizedBox(height: 40),
                                Center(
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(22),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: colorScheme
                                              .surfaceContainerHighest
                                              .withOpacity(0.6),
                                        ),
                                        child: Icon(
                                          Icons.devices_rounded,
                                          size: 48,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        'No saved desktops yet',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                        ),
                                        child: Text(
                                          'Add a connection with your computer’s IP and default ports (TCP 5000, UDP 6000).',
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                                height: 1.4,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PortChip extends StatelessWidget {
  const _PortChip({
    required this.label,
    required this.icon,
    required this.colorScheme,
  });

  final String label;
  final IconData icon;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.65),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
        ],
      ),
    );
  }
}
