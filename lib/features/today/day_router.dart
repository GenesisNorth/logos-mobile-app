import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../encounter/encounter_screen.dart';
import '../examen/examen_screen.dart';
import '../exchange/exchange_screen.dart';
import '../journey/bloc/journey_bloc.dart';
import '../recap/recap_screen.dart';
import '../roots/roots_screen.dart';
import '../stillness/stillness_screen.dart';

/// Opens a day's practice full-screen (practices are not tabs).
void openDay(BuildContext context, int day) {
  final s = context.read<JourneyBloc>().state;
  final drop = s.activeDrop;
  final Widget screen = switch (day) {
    1 => EncounterScreen(drop: drop, startWithRecitation: s.dayCompletionStatus[1] == true),
    2 => RootsScreen(drop: drop),
    3 => StillnessScreen(drop: drop),
    _ => s.dayCompletionStatus[4] == true ? RecapScreen(drop: drop) : ExchangeScreen(drop: drop),
  };
  Navigator.of(context).push(_fade(screen));
}

void openExamen(BuildContext context) => Navigator.of(context).push(_fade(const ExamenScreen()));

/// Practices fade in like a change of atmosphere.
PageRoute<void> _fade(Widget child) => PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => child,
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: CurvedAnimation(parent: a, curve: Curves.easeOut), child: c),
    );
