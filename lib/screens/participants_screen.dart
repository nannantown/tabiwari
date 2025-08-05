import 'package:flutter/material.dart';
import '../models/participant.dart';
import '../services/storage_service.dart';

class ParticipantsScreen extends StatefulWidget {
  final VoidCallback? onDataChanged;

  const ParticipantsScreen({super.key, this.onDataChanged});

  @override
  State<ParticipantsScreen> createState() => ParticipantsScreenState();
}

class ParticipantsScreenState extends State<ParticipantsScreen> {
  List<Participant> _participants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => _isLoading = true);
    try {
      _participants = await StorageService.loadParticipants();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('参加者データの読み込みに失敗しました: $e')),
        );
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveParticipants() async {
    try {
      await StorageService.saveParticipants(_participants);
      widget.onDataChanged?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e')),
        );
      }
    }
  }

  void _addParticipant() {
    showDialog(
      context: context,
      builder: (context) => _ParticipantDialog(
        onSave: (name) {
          final participant = Participant(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: name,
          );
          setState(() {
            _participants.add(participant);
          });
          _saveParticipants();
        },
      ),
    );
  }

  void _editParticipant(Participant participant) {
    showDialog(
      context: context,
      builder: (context) => _ParticipantDialog(
        initialName: participant.name,
        onSave: (name) {
          setState(() {
            final index =
                _participants.indexWhere((p) => p.id == participant.id);
            if (index != -1) {
              _participants[index] =
                  Participant(id: participant.id, name: name);
            }
          });
          _saveParticipants();
        },
      ),
    );
  }

  void _deleteParticipant(Participant participant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('参加者を削除'),
        content: Text('${participant.name}を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _participants.removeWhere((p) => p.id == participant.id);
              });
              _saveParticipants();
              Navigator.pop(context);
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: _participants.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    '参加者が登録されていません',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '右下の + ボタンから追加してください',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _participants.length,
              itemBuilder: (context, index) {
                final participant = _participants[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF15283A),
                      child: Text(
                        participant.name.isNotEmpty ? participant.name[0] : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      participant.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editParticipant(participant),
                          tooltip: '編集',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteParticipant(participant),
                          tooltip: '削除',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addParticipant,
        tooltip: '参加者を追加',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ParticipantDialog extends StatefulWidget {
  final String? initialName;
  final Function(String) onSave;

  const _ParticipantDialog({
    this.initialName,
    required this.onSave,
  });

  @override
  State<_ParticipantDialog> createState() => _ParticipantDialogState();
}

class _ParticipantDialogState extends State<_ParticipantDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialName == null ? '参加者を追加' : '参加者を編集'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: '名前',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _controller.text.trim();
            if (name.isNotEmpty) {
              widget.onSave(name);
              Navigator.pop(context);
            }
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
