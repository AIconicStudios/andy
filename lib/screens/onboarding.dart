import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../reminders.dart';
import '../state.dart';
import '../widgets.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final _name = TextEditingController();
  final _goal = TextEditingController(text: '2200');

  @override
  void dispose() {
    _name.dispose();
    _goal.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final goal = int.tryParse(_goal.text) ?? 2200;
    final s = AndyScope.of(context);
    if (reminders.available) {
      s.remindersOn = await reminders.requestPermission();
    }
    s.finishOnboarding(
      _name.text.trim().isEmpty ? 'friend' : _name.text,
      goal.clamp(1000, 6000),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AndyMark(size: 72),
                  const SizedBox(height: 28),
                  Text('Keep it handy\nwith Andy.',
                      style: t.textTheme.displaySmall),
                  const SizedBox(height: 14),
                  Text(
                    'I keep an eye on four things: what you eat, how you move, '
                    'the people you love, and you. I will nudge you when one '
                    'slips, and on the days you forget what you are worth, I '
                    'will remind you.',
                    style: t.textTheme.bodyLarge?.copyWith(
                        color: t.colorScheme.onSurfaceVariant, height: 1.45),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration:
                        const InputDecoration(labelText: 'What do I call you?'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _goal,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Daily calorie goal',
                      suffixText: 'kcal',
                      helperText: 'Not sure? 2200 is a fine start. Change it any time.',
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _start,
                      child: const Text('Let\'s go'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
