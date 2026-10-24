import 'package:flutter/material.dart';
import 'package:ravix/data/tag_repository.dart';

/// Tamanho máximo do nome de uma tag.
const tamanhoMaximoNomeTag = 40;

/// Pede o nome de uma tag e chama [aoSalvar]. Se [aoSalvar] lançar
/// [NomeTagVazio] ou [NomeTagRepetido], mostra a mensagem no campo e o
/// diálogo continua aberto; em caso de sucesso, fecha.
Future<void> mostrarDialogoNomeTag(
  BuildContext context, {
  required String titulo,
  required String rotuloSalvar,
  required Future<void> Function(String nome) aoSalvar,
  String nomeInicial = '',
}) => showDialog<void>(
  context: context,
  builder: (_) => _DialogoNomeTag(
    titulo: titulo,
    rotuloSalvar: rotuloSalvar,
    aoSalvar: aoSalvar,
    nomeInicial: nomeInicial,
  ),
);

class _DialogoNomeTag extends StatefulWidget {
  const new({
    required this.titulo,
    required this.rotuloSalvar,
    required this.aoSalvar,
    required this.nomeInicial,
  });

  final String titulo;
  final String rotuloSalvar;
  final Future<void> Function(String nome) aoSalvar;
  final String nomeInicial;

  @override
  State<_DialogoNomeTag> createState() => _DialogoNomeTagState();
}

class _DialogoNomeTagState extends State<_DialogoNomeTag> {
  late final _campo = TextEditingController(text: widget.nomeInicial)
    ..selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.nomeInicial.length,
    );
  String? _erro;
  bool _salvando = false;

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await widget.aoSalvar(_campo.text);
      if (mounted) Navigator.of(context).pop();
    } on NomeTagVazio catch (e) {
      setState(() => _erro = e.toString());
    } on NomeTagRepetido catch (e) {
      setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: TextField(
        controller: _campo,
        autofocus: true,
        maxLength: tamanhoMaximoNomeTag,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onChanged: (_) {
          if (_erro != null) setState(() => _erro = null);
        },
        onSubmitted: (_) => _salvar(),
        decoration: InputDecoration(
          labelText: 'Nome da tag',
          hintText: 'Ex.: Viagem, Rolê, Aniversário',
          errorText: _erro,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _salvando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _salvando ? null : _salvar,
          child: Text(widget.rotuloSalvar),
        ),
      ],
    );
  }
}
