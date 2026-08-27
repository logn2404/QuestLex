import 'package:flutter/material.dart';
import '../../models/vocab_items.dart'; // Sửa lại tên file model nếu của bạn không có 's'

class VocabListTile extends StatelessWidget {
  final VocabItem vocab;

  const VocabListTile({super.key, required this.vocab});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple,
          child: Text(vocab.word.isNotEmpty ? vocab.word[0] : '?'),
        ),
        title: Text(vocab.word, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${vocab.type} - ${vocab.meaning}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}