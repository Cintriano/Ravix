// Tela de exemplo para conferir o tema. Rode com:
//   flutter run -t lib/ravix_preview.dart
// Os lançamentos são os mesmos das telas atuais do app. O orçamento de R$ 800,00 é um exemplo.

import 'package:flutter/material.dart';

import 'theme/ravix_theme.dart';
import 'widgets/ravix_brand.dart';

void main() => runApp(const RavixPreviewApp());

class RavixPreviewApp extends StatefulWidget {
  const RavixPreviewApp({super.key});

  @override
  State<RavixPreviewApp> createState() => _RavixPreviewAppState();
}

class _RavixPreviewAppState extends State<RavixPreviewApp> {
  ThemeMode _mode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ravix',
      debugShowCheckedModeBanner: false,
      theme: RavixTheme.light,
      darkTheme: RavixTheme.dark,
      themeMode: _mode,
      home: MonitorPreview(
        onToggleTheme: () => setState(() {
          final dark = _mode == ThemeMode.dark ||
              (_mode == ThemeMode.system &&
                  WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);
          _mode = dark ? ThemeMode.light : ThemeMode.dark;
        }),
      ),
    );
  }
}

class MonitorPreview extends StatelessWidget {
  const MonitorPreview({super.key, required this.onToggleTheme});
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    const c = RavixColors.chart;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.chevron_left_sharp), onPressed: () {}),
        title: const Text('Novembro de 2026'),
        actions: [
          IconButton(icon: const Icon(Icons.contrast_sharp), tooltip: 'Trocar tema', onPressed: onToggleTheme),
          IconButton(icon: const Icon(Icons.chevron_right_sharp), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: RavixSummaryCard(
              total: 461.89,
              budget: 800,
              categories: [
                RavixCategoryShare('Combustível', 200.00, RavixColors.menta),
                RavixCategoryShare('Contas', 119.90, RavixColors.petroleo),
                RavixCategoryShare('Delivery', 56.50, Color(0xFF4FA3A0)),
                RavixCategoryShare('Refeição', 50.14, RavixColors.areia),
                RavixCategoryShare('Padaria', 35.35, Color(0xFFA9C9BC)),
              ],
            ),
          ),
          RavixDayHeader(label: 'Hoje, 6 de novembro', subtotal: 159.46),
          RavixExpenseTile(title: 'Colombo', detail: 'Padaria · 16:28 · Lanche da tarde', amount: 18.46, icon: Icons.bakery_dining_sharp, color: RavixColors.areia),
          RavixExpenseTile(title: 'Almoço no Sesc', detail: 'Refeição · 13:37 · Rotina', amount: 21.10, icon: Icons.restaurant_sharp, color: RavixColors.menta),
          RavixExpenseTile(title: 'Internet Pronto Fibra', detail: 'Contas de consumo · 08:00 · Rotina', amount: 119.90, icon: Icons.wifi_sharp, color: Color(0xFF4FA3A0)),
          RavixDayHeader(label: 'Quarta, 4 de novembro', subtotal: 216.89),
          RavixExpenseTile(title: 'Colombo', detail: 'Padaria · 16:41 · Lanche da tarde', amount: 16.89, icon: Icons.bakery_dining_sharp, color: RavixColors.areia),
          RavixExpenseTile(title: 'Combustível', detail: 'Combustível · 16:37 · Rotina', amount: 200.00, icon: Icons.local_gas_station_sharp, color: RavixColors.menta),
          RavixDayHeader(label: 'Terça, 3 de novembro', subtotal: 29.04),
          RavixExpenseTile(title: 'Almoço no Sesc', detail: 'Refeição · 13:43 · Rotina', amount: 29.04, icon: Icons.restaurant_sharp, color: RavixColors.menta),
          RavixDayHeader(label: 'Segunda, 2 de novembro', subtotal: 56.50),
          RavixExpenseTile(title: 'Pizza G calabresa - pizzaria quinta', detail: 'Delivery · 19:27', amount: 56.50, icon: Icons.delivery_dining_sharp, color: Color(0xFF4FA3A0)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const NewExpensePreview())),
        icon: const Icon(Icons.add_sharp),
        label: const Text('Novo gasto'),
      ),
    );
  }
}

class NewExpensePreview extends StatefulWidget {
  const NewExpensePreview({super.key});

  @override
  State<NewExpensePreview> createState() => _NewExpensePreviewState();
}

class _NewExpensePreviewState extends State<NewExpensePreview> {
  String _payment = 'Pix';

  @override
  Widget build(BuildContext context) {
    final t = context.ravix;
    return Scaffold(
      appBar: AppBar(title: const Text('Novo gasto')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: t.moneyHero.copyWith(fontSize: 30, color: Theme.of(context).colorScheme.onSurface),
            decoration: const InputDecoration(labelText: 'Valor', prefixText: r'R$ '),
          ),
          const SizedBox(height: 10),
          const TextField(decoration: InputDecoration(labelText: 'Descrição', hintText: 'Ex.: Padaria do Zé')),
          const SizedBox(height: 10),
          const Row(children: [
            Expanded(child: TextField(decoration: InputDecoration(labelText: 'Data', suffixIcon: Icon(Icons.calendar_today_sharp)))),
            SizedBox(width: 10),
            Expanded(child: TextField(decoration: InputDecoration(labelText: 'Hora', suffixIcon: Icon(Icons.schedule_sharp)))),
          ]),
          const SizedBox(height: 16),
          Text('Forma de pagamento', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: t.textMuted)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final p in const ['Pix', 'Débito', 'Dinheiro', 'Voucher'])
              ChoiceChip(label: Text(p), selected: _payment == p, onSelected: (_) => setState(() => _payment = p)),
          ]),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Categoria'),
            items: const [
              DropdownMenuItem(value: 'Padaria', child: Text('Padaria')),
              DropdownMenuItem(value: 'Refeição', child: Text('Refeição')),
              DropdownMenuItem(value: 'Combustível', child: Text('Combustível')),
            ],
            onChanged: (_) {},
          ),
          const SizedBox(height: 10),
          const TextField(decoration: InputDecoration(labelText: 'Tag (opcional)', helperText: 'Contexto do gasto, como viagem ou rolê')),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gasto salvo. Restam R\$ 338,11 no mês.')));
            },
            icon: const Icon(Icons.check_sharp),
            label: const Text('Salvar gasto'),
          ),
        ],
      ),
    );
  }
}
