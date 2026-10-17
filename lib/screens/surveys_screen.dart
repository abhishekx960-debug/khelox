import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/khelox_app_bar.dart';

class SurveysScreen extends StatefulWidget {
  const SurveysScreen({super.key});

  @override
  State<SurveysScreen> createState() => _SurveysScreenState();
}

class _SurveysScreenState extends State<SurveysScreen> {
  static const _surveys = <_Survey>[
    _Survey('Gaming Habits', 'How often do you play mobile games?', 5, 25, 2),
    _Survey('Esports Preferences', 'Which esports titles do you follow?', 4, 20, 2),
    _Survey('App Feedback', 'Tell us how we can improve the app.', 3, 15, 1),
    _Survey('Tournament Interest', 'Would you join paid tournaments?', 6, 30, 3),
    _Survey('Payment Experience', 'How was your deposit experience?', 4, 20, 2),
  ];

  final Set<int> _done = {};

  void _start(int i) {
    final survey = _surveys[i];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _SurveySheet(
        survey: survey,
        onSubmit: () {
          Navigator.pop(ctx);
          setState(() => _done.add(i));
          showMsg(
            context,
            'Survey completed! You earned ${survey.reward} Fcoin',
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KheloxAppBar('Surveys'),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        itemCount: _surveys.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, i) {
          final survey = _surveys[i];
          final done = _done.contains(i);
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.surfaceCard(
              border: done ? AppColors.teal : AppColors.line,
              radius: 18,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.cyan.withValues(alpha: 0.15),
                  ),
                  child: const Icon(
                    Icons.poll_rounded,
                    color: AppColors.cyan,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        survey.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${survey.questions} questions - ${survey.minutes} min',
                        style: const TextStyle(
                          color: AppColors.mist,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.monetization_on_rounded,
                            color: AppColors.gold,
                            size: 15,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${survey.reward} Fcoin',
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                done
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.gold,
                        size: 26,
                      )
                    : TextButton(
                        onPressed: () => _start(i),
                        child: const Text('Start'),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Survey {
  final String title;
  final String question;
  final int questions;
  final int reward;
  final int minutes;

  const _Survey(
    this.title,
    this.question,
    this.questions,
    this.reward,
    this.minutes,
  );
}

class _SurveySheet extends StatefulWidget {
  final _Survey survey;
  final VoidCallback onSubmit;

  const _SurveySheet({required this.survey, required this.onSubmit});

  @override
  State<_SurveySheet> createState() => _SurveySheetState();
}

class _SurveySheetState extends State<_SurveySheet> {
  static const _options = <String>[
    'Very often',
    'Sometimes',
    'Rarely',
    'Never',
  ];

  int? _selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            widget.survey.title,
            style: const TextStyle(
              fontFamily: AppFonts.heading,
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.survey.question,
            style: const TextStyle(color: AppColors.mist, fontSize: 14),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < _options.length; i++)
            GestureDetector(
              onTap: () => setState(() => _selected = i),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selected == i ? AppColors.gold : AppColors.line,
                  ),
                  color: _selected == i
                      ? AppColors.gold.withValues(alpha: 0.12)
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Icon(
                      _selected == i
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: _selected == i ? AppColors.gold : AppColors.mist,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _options[i],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _selected == null ? null : widget.onSubmit,
            child: Text('SUBMIT & EARN ${widget.survey.reward} FCOIN'),
          ),
        ],
      ),
    );
  }
}
