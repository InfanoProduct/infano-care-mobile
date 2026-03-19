import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardState extends Equatable {
  final int selectedIndex;
  final bool hasLearnNotification;
  final bool isPeriodImminent;
  final int questBadgeCount;
  final bool hasConnectNotification;

  const DashboardState({
    this.selectedIndex = 0,
    this.hasLearnNotification = true, // Mocked initial state
    this.isPeriodImminent = true,     // Mocked initial state
    this.questBadgeCount = 1,        // Mocked initial state
    this.hasConnectNotification = true, // Mocked initial state
  });

  DashboardState copyWith({
    int? selectedIndex,
    bool? hasLearnNotification,
    bool? isPeriodImminent,
    int? questBadgeCount,
    bool? hasConnectNotification,
  }) {
    return DashboardState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      hasLearnNotification: hasLearnNotification ?? this.hasLearnNotification,
      isPeriodImminent: isPeriodImminent ?? this.isPeriodImminent,
      questBadgeCount: questBadgeCount ?? this.questBadgeCount,
      hasConnectNotification: hasConnectNotification ?? this.hasConnectNotification,
    );
  }

  @override
  List<Object> get props => [
    selectedIndex,
    hasLearnNotification,
    isPeriodImminent,
    questBadgeCount,
    hasConnectNotification,
  ];
}

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit() : super(const DashboardState());

  void setTab(int index) {
    emit(state.copyWith(selectedIndex: index));
    
    // Clear notifications when entering tabs
    if (index == 1) emit(state.copyWith(hasLearnNotification: false));
    if (index == 3) emit(state.copyWith(questBadgeCount: 0));
    if (index == 4) emit(state.copyWith(hasConnectNotification: false));
  }

  void updateTrackStatus({required bool isImminent}) {
    emit(state.copyWith(isPeriodImminent: isImminent));
  }
}
