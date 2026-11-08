import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/journey/bloc/journey_bloc.dart';
import '../../features/journey/data/progress_repository.dart';

/// The name the pilgrim signed the covenant with, or the neutral default when
/// no [JourneyBloc] is in scope (e.g. a screen pumped in isolation in tests).
String pilgrimName(BuildContext context) {
  try {
    return context.read<JourneyBloc>().state.profile.displayName;
  } catch (_) {
    return UserProfileData.defaultDisplayName;
  }
}
