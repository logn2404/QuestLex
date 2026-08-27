import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:questlex/features/home/presentation/trigger_config_controller.dart';

class TriggerSettingsBottomSheet extends StatelessWidget {
  const TriggerSettingsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TriggerConfigController>();
    final config = controller.config;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '⚙️ Cấu hình Trigger Chụp',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),

            // 1. TIMER TRIGGER
            SwitchListTile(
              title: const Text('⏱️ Tự động chụp theo thời gian (Timer)'),
              subtitle: Text('Chụp mỗi ${(config.timerIntervalMs / 1000).toStringAsFixed(1)} giây'),
              value: config.enableTimer,
              onChanged: (val) {
                controller.updateConfig(enableTimer: val);
              },
            ),
            if (config.enableTimer)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    const Text('Chu kỳ: ', style: TextStyle(fontSize: 13)),
                    Expanded(
                      child: Slider(
                        value: config.timerIntervalMs.toDouble(),
                        min: 1000,
                        max: 10000,
                        divisions: 18,
                        label: '${(config.timerIntervalMs / 1000).toStringAsFixed(1)}s',
                        onChanged: (val) {
                          controller.updateConfig(timerIntervalMs: val.toInt());
                        },
                      ),
                    ),
                  ],
                ),
              ),

            const Divider(),

            // 2. CLICK TRIGGER
            SwitchListTile(
              title: const Text('🖱️ Chụp khi Click chuột (Left Click)'),
              subtitle: Text('Kích hoạt sau ${config.clickThreshold} lần nhấp chuột'),
              value: config.enableClick,
              onChanged: (val) {
                controller.updateConfig(enableClick: val);
              },
            ),
            if (config.enableClick)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    const Text('Số lần nhấp: ', style: TextStyle(fontSize: 13)),
                    Expanded(
                      child: Slider(
                        value: config.clickThreshold.toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: '${config.clickThreshold} lần',
                        onChanged: (val) {
                          controller.updateConfig(clickThreshold: val.toInt());
                        },
                      ),
                    ),
                  ],
                ),
              ),

            const Divider(),

            // 3. SCROLL TRIGGER
            SwitchListTile(
              title: const Text('📜 Chụp khi Lăn chuột (Scroll)'),
              subtitle: Text('Quét khi cuộn đạt ${config.scrollThreshold.toInt()} px'),
              value: config.enableScroll,
              onChanged: (val) {
                controller.updateConfig(enableScroll: val);
              },
            ),
            if (config.enableScroll)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Độ nhạy cuộn: ', style: TextStyle(fontSize: 13)),
                        Expanded(
                          child: Slider(
                            value: config.scrollThreshold,
                            min: 50,
                            max: 1000,
                            divisions: 19,
                            label: '${config.scrollThreshold.toInt()} px',
                            onChanged: (val) {
                              controller.updateConfig(scrollThreshold: val);
                            },
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            // 1. Icon bóng đèn giữ dáng đứng thẳng đẹp
                            const TextSpan(
                              text: '💡 ',
                              style: TextStyle(fontStyle: FontStyle.normal),
                            ),
                            // 2. Chữ chú thích phía sau in nghiêng
                            TextSpan(
                              text: config.scrollThreshold <= 150
                                  ? 'Phù hợp: Báo chữ nhỏ / Manga cuộn ngắn'
                                  : (config.scrollThreshold <= 400
                                      ? 'Phù hợp: Game dialogue / Web thông thường'
                                      : 'Phù hợp: Giao diện chữ to / Cuộn xa'),
                              style: const TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }
}