import 'package:flutter/material.dart';

import '../app/settings.dart';
import '../app/task_controller.dart';
import 'themes.dart';

class AppearanceSettings extends StatelessWidget {
  const AppearanceSettings({super.key, required this.controller});
  final TaskController controller;
  @override
  Widget build(BuildContext context) {
    final settings = controller.settings, a = settings.appearance;
    final base = themeById(settings.themeId), spec = customizedTheme(base, a);
    void update(Appearance next) {
      controller.updateSettings(controller.settings.copyWith(appearance: next));
    }

    final colors = <String, (String, Color, int?)>{
      'primary': ('Vurgu rengi', spec.primary, a.primary),
      'secondary': ('İkinci vurgu', spec.secondary, a.secondary),
      'background': ('Arka plan', spec.gradient.first, a.background),
      'surface': ('Kartlar ve paneller', spec.surface, a.surface),
    };
    final text = readableOn(spec.gradient.first);
    final light = text.computeLuminance(),
        card = spec.surface.computeLuminance();
    final contrast =
        (light > card ? light + .05 : card + .05) /
        (light > card ? card + .05 : light + .05);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kendi temanı oluştur',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Hazır bir temadan başla; renkleri, köşeleri ve yazı stilini kendine göre değiştir.',
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final e in colors.entries)
                  ListTile(
                    key: Key('color-${e.key}'),
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: e.value.$2,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                    title: Text(e.value.$1),
                    subtitle: Text(
                      '#${hexOf(e.value.$2)}${e.value.$3 == null ? ' · hazır tema' : ''}',
                    ),
                    trailing: IconButton(
                      key: Key('color-reset-${e.key}'),
                      tooltip: '${e.value.$1}: hazır tema rengine dön',
                      onPressed: e.value.$3 == null
                          ? null
                          : () => update(
                              controller.settings.appearance.withColor(
                                e.key,
                                null,
                              ),
                            ),
                      icon: const Icon(Icons.restart_alt, size: 20),
                    ),
                    onTap: () async {
                      final picked = await showColorPicker(
                        context,
                        initial: e.value.$2,
                        title: e.value.$1,
                      );
                      if (picked != null) {
                        update(
                          controller.settings.appearance.withColor(
                            e.key,
                            picked.toARGB32(),
                          ),
                        );
                      }
                    },
                  ),
                const Divider(height: 28),
                Text(
                  'Köşe yuvarlaklığı: ${(a.radius ?? base.radius).round()} px',
                  key: const Key('radius-label'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Slider(
                  key: const Key('theme-radius'),
                  min: 4,
                  max: 32,
                  divisions: 14,
                  label: '${(a.radius ?? base.radius).round()} px',
                  value: (a.radius ?? base.radius).clamp(4, 32),
                  onChanged: (v) => update(
                    controller.settings.appearance.copyWith(radius: v),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Yazı stili'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (id, label) in [
                      ('system', 'Sistem'),
                      ('serif', 'Serif'),
                      ('mono', 'Kod'),
                    ])
                      ChoiceChip(
                        key: Key('font-$id'),
                        label: Text(label),
                        selected: a.font == id,
                        onSelected: (_) => update(
                          controller.settings.appearance.copyWith(font: id),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  key: const Key('theme-compact'),
                  title: const Text('Sıkı denetimler'),
                  subtitle: const Text(
                    'Listelerde ve düğmelerde daha az boşluk',
                  ),
                  value: a.compact,
                  onChanged: (v) => update(
                    controller.settings.appearance.copyWith(compact: v),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  key: const Key('theme-reduce-motion'),
                  title: const Text('Yol arkadaşı animasyonlarını azalt'),
                  value: a.reduceMotion,
                  onChanged: (v) => update(
                    controller.settings.appearance.copyWith(reduceMotion: v),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Canlı önizleme',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Theme(
                  data: buildTheme(spec, appearance: a),
                  child: Builder(
                    builder: (context) => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: spec.gradient.first,
                        borderRadius: BorderRadius.circular(spec.radius),
                      ),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Küçük bir adım, yeni bir başlangıç.',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    '18:30 · Kitabımdan bir sayfa',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                  FilledButton(
                                    onPressed: () {},
                                    child: const Text('Tamamla'),
                                  ),
                                  Chip(
                                    label: const Text('+20 XP'),
                                    backgroundColor: spec.secondary.withValues(
                                      alpha: .15,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (contrast < 4.5)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Kart metni kontrastı düşük (${contrast.toStringAsFixed(1)}:1). Kartın veya arka planın açıklığını değiştir.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                TextButton.icon(
                  key: const Key('appearance-reset'),
                  onPressed: () => update(const Appearance()),
                  icon: const Icon(Icons.restore),
                  label: const Text('Özel görünümü sıfırla'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String hexOf(Color color) => color
    .toARGB32()
    .toRadixString(16)
    .padLeft(8, '0')
    .substring(2)
    .toUpperCase();

Future<Color?> showColorPicker(
  BuildContext context, {
  required Color initial,
  required String title,
}) => showDialog<Color>(
  context: context,
  builder: (_) => _ColorPicker(initial: initial, title: title),
);

class _ColorPicker extends StatefulWidget {
  const _ColorPicker({required this.initial, required this.title});
  final Color initial;
  final String title;
  @override
  State<_ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<_ColorPicker> {
  late HSVColor hsv = HSVColor.fromColor(widget.initial);
  late final TextEditingController hex = TextEditingController(
    text: hexOf(widget.initial),
  );
  bool valid = true;
  @override
  void dispose() {
    hex.dispose();
    super.dispose();
  }

  void pick(HSVColor value) {
    setState(() {
      hsv = value;
      valid = true;
      hex.text = hexOf(value.toColor());
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('${widget.title} seç'),
    scrollable: true,
    content: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 170,
            child: LayoutBuilder(
              builder: (context, c) {
                void position(Offset p) => pick(
                  hsv
                      .withSaturation((p.dx / c.maxWidth).clamp(0, 1))
                      .withValue((1 - p.dy / 170).clamp(0, 1)),
                );
                return Semantics(
                  label: 'Doygunluk ve parlaklık renk alanı. Aşağıdaki kaydırıcılarla da ayarlanabilir.',
                  child: GestureDetector(
                    key: const Key('color-field'),
                    onPanDown: (d) => position(d.localPosition),
                    onPanUpdate: (d) => position(d.localPosition),
                    child: SizedBox(
                      height: 170,
                      width: double.infinity,
                      child: CustomPaint(painter: _ColorField(hsv)),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: hsv.toColor(),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  key: const Key('color-hex'),
                  controller: hex,
                  maxLength: 7,
                  decoration: InputDecoration(
                    labelText: 'HEX renk kodu',
                    prefixText: '#',
                    counterText: '',
                    errorText: valid ? null : '6 haneli HEX gir (örn. 7C5CFC)',
                  ),
                  onChanged: (text) {
                    final t = text.replaceFirst('#', '');
                    setState(() {
                      valid = RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(t);
                      if (valid) {
                        hsv = HSVColor.fromColor(
                          Color(0xff000000 | int.parse(t, radix: 16)),
                        );
                      }
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Ton · ${hsv.hue.round()}°'),
          Slider(
            key: const Key('color-hue'),
            min: 0,
            max: 360,
            divisions: 360,
            value: hsv.hue.clamp(0, 360),
            onChanged: (v) => pick(hsv.withHue(v)),
          ),
          Text('Doygunluk · ${(hsv.saturation * 100).round()}%'),
          Slider(
            key: const Key('color-saturation'),
            value: hsv.saturation,
            onChanged: (v) => pick(hsv.withSaturation(v)),
          ),
          Text('Parlaklık · ${(hsv.value * 100).round()}%'),
          Slider(
            key: const Key('color-brightness'),
            value: hsv.value,
            onChanged: (v) => pick(hsv.withValue(v)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              for (final value in [
                0xff527b62,
                0xff7c5cfc,
                0xff3677bb,
                0xffc96772,
                0xffc98c40,
                0xff1c1d2b,
                0xfff7f8f2,
                0xfffffefa,
                0xff243c40,
                0xffb8c7bc,
                0xfff2d4cf,
                0xffd6d0ef,
              ])
                Semantics(
                  label: 'Renk ${hexOf(Color(value))}',
                  button: true,
                  child: InkWell(
                    onTap: () => pick(HSVColor.fromColor(Color(value))),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Color(value),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline
                              .withValues(alpha: .4),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Vazgeç'),
      ),
      FilledButton(
        key: const Key('color-apply'),
        onPressed: valid ? () => Navigator.pop(context, hsv.toColor()) : null,
        child: const Text('Rengi uygula'),
      ),
    ],
  );
}

class _ColorField extends CustomPainter {
  const _ColorField(this.hsv);
  final HSVColor hsv;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white, HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor()],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );
    final center = Offset(
      hsv.saturation * size.width,
      (1 - hsv.value) * size.height,
    );
    canvas.drawCircle(
      center,
      7,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(
      center,
      6,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_ColorField old) => old.hsv != hsv;
}
