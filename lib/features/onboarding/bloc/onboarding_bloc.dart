import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/features/onboarding/data/onboarding_repository.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class OnboardingState extends Equatable {
  final String userType;          // 'teen' | 'parent'
  final String displayName;
  final String? pronouns;
  final String phone;
  final int birthMonth;           // 1–12
  final int birthYear;
  final int age;
  final String contentTier;       // JUNIOR | TEEN_EARLY | TEEN_LATE | ADULT
  final bool coppaRequired;
  final bool termsAccepted;
  final bool privacyAccepted;
  final bool marketingOptIn;
  final List<String> goals;
  final int periodComfortScore;   // 1–5
  final String periodStatus;      // active | waiting | unsure
  final List<String> interestTopics;
  final Map<String, dynamic> avatarData;
  final String journeyName;
  final int totalPoints;
  final DateTime? lastPeriod;
  final int periodLength;        // 2–10
  final int cycleLength;         // 21–45
  final bool isLoading;
  final String? errorMessage;
  final bool sessionExpired;

  const OnboardingState({
    this.userType           = 'teen',
    this.displayName        = '',
    this.pronouns,
    this.phone              = '',
    this.birthMonth         = 1,
    this.birthYear          = 2010,
    this.age                = 15,
    this.contentTier        = 'TEEN_EARLY',
    this.coppaRequired      = false,
    this.termsAccepted      = false,
    this.privacyAccepted    = false,
    this.marketingOptIn     = false,
    this.goals              = const [],
    this.periodComfortScore = 3,
    this.periodStatus       = 'waiting',
    this.interestTopics     = const [],
    this.avatarData         = const {},
    this.journeyName        = '',
    this.totalPoints        = 0,
    this.lastPeriod,
    this.periodLength       = 5,
    this.cycleLength        = 28,
    this.isLoading          = false,
    this.errorMessage,
    this.sessionExpired     = false,
  });

  OnboardingState copyWith({
    String? userType, String? displayName, String? pronouns, String? phone,
    int? birthMonth, int? birthYear, int? age, String? contentTier,
    bool? coppaRequired, bool? termsAccepted, bool? privacyAccepted,
    bool? marketingOptIn, List<String>? goals, int? periodComfortScore,
    String? periodStatus, List<String>? interestTopics,
    Map<String, dynamic>? avatarData, String? journeyName,
    int? totalPoints, DateTime? lastPeriod, int? periodLength, int? cycleLength,
    bool? isLoading, String? errorMessage, bool? sessionExpired,
  }) {
    return OnboardingState(
      userType:           userType          ?? this.userType,
      displayName:        displayName       ?? this.displayName,
      pronouns:           pronouns          ?? this.pronouns,
      phone:              phone             ?? this.phone,
      birthMonth:         birthMonth        ?? this.birthMonth,
      birthYear:          birthYear         ?? this.birthYear,
      age:                age               ?? this.age,
      contentTier:        contentTier       ?? this.contentTier,
      coppaRequired:      coppaRequired     ?? this.coppaRequired,
      termsAccepted:      termsAccepted     ?? this.termsAccepted,
      privacyAccepted:    privacyAccepted   ?? this.privacyAccepted,
      marketingOptIn:     marketingOptIn    ?? this.marketingOptIn,
      goals:              goals             ?? this.goals,
      periodComfortScore: periodComfortScore ?? this.periodComfortScore,
      periodStatus:       periodStatus      ?? this.periodStatus,
      interestTopics:     interestTopics    ?? this.interestTopics,
      avatarData:         avatarData        ?? this.avatarData,
      journeyName:        journeyName       ?? this.journeyName,
      totalPoints:        totalPoints       ?? this.totalPoints,
      lastPeriod:         lastPeriod        ?? this.lastPeriod,
      periodLength:       periodLength      ?? this.periodLength,
      cycleLength:        cycleLength       ?? this.cycleLength,
      isLoading:          isLoading         ?? this.isLoading,
      errorMessage:       errorMessage,
      sessionExpired:     sessionExpired    ?? this.sessionExpired,
    );
  }

  @override
  List<Object?> get props => [
    userType, displayName, pronouns, phone, birthMonth, birthYear, age,
    contentTier, coppaRequired, termsAccepted, privacyAccepted, marketingOptIn,
    goals, periodComfortScore, periodStatus, interestTopics, avatarData,
    journeyName, totalPoints, lastPeriod, periodLength, cycleLength,
    isLoading, errorMessage, sessionExpired,
  ];
}

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();
  @override List<Object?> get props => [];
}

class SetUserType          extends OnboardingEvent { final String t; const SetUserType(this.t); @override List<Object?> get props => [t]; }
class SetDisplayName       extends OnboardingEvent { final String name; final String? pronouns; const SetDisplayName(this.name, this.pronouns); @override List<Object?> get props => [name, pronouns]; }
class SetPhone             extends OnboardingEvent { final String phone; const SetPhone(this.phone); @override List<Object?> get props => [phone]; }
class SetBirthDate         extends OnboardingEvent { final int month; final int year; const SetBirthDate(this.month, this.year); @override List<Object?> get props => [month, year]; }
class SetConsent           extends OnboardingEvent { final bool terms; final bool privacy; final bool marketing; const SetConsent(this.terms, this.privacy, this.marketing); @override List<Object?> get props => [terms, privacy, marketing]; }
class SetGoals             extends OnboardingEvent { final List<String> goals; const SetGoals(this.goals); @override List<Object?> get props => [goals]; }
class SetPeriodComfort     extends OnboardingEvent { final int score; const SetPeriodComfort(this.score); @override List<Object?> get props => [score]; }
class SetPeriodStatus      extends OnboardingEvent { final String status; const SetPeriodStatus(this.status); @override List<Object?> get props => [status]; }
class SetInterestTopics    extends OnboardingEvent { final List<String> topics; const SetInterestTopics(this.topics); @override List<Object?> get props => [topics]; }
class SetAvatar            extends OnboardingEvent { final Map<String, dynamic> data; const SetAvatar(this.data); @override List<Object?> get props => [data]; }
class SetJourneyName       extends OnboardingEvent { final String name; const SetJourneyName(this.name); @override List<Object?> get props => [name]; }
class SetTrackerDetails    extends OnboardingEvent { final int periodDays; final int cycleDays; final DateTime? lastPeriod; const SetTrackerDetails(this.periodDays, this.cycleDays, this.lastPeriod); @override List<Object?> get props => [periodDays, cycleDays, lastPeriod]; }
class AddPoints            extends OnboardingEvent { final int points; const AddPoints(this.points); @override List<Object?> get props => [points]; }
class SubmitRegistration   extends OnboardingEvent { final String tempToken; const SubmitRegistration(this.tempToken); @override List<Object?> get props => [tempToken]; }
class SubmitPersonalization extends OnboardingEvent { const SubmitPersonalization(); }
class SubmitAvatar          extends OnboardingEvent { const SubmitAvatar(); }
class SubmitJourneyName     extends OnboardingEvent { const SubmitJourneyName(); }
class SubmitTrackerSetup    extends OnboardingEvent { const SubmitTrackerSetup(); }
class SyncFromStorage       extends OnboardingEvent { const SyncFromStorage(); }

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final OnboardingRepository _repo;
  final LocalStorageService  _storage;

  OnboardingBloc(this._repo, this._storage) : super(const OnboardingState()) {
    on<SetUserType>(_onSetUserType);
    on<SetDisplayName>(_onSetDisplayName);
    on<SetPhone>(_onSetPhone);
    on<SetBirthDate>(_onSetBirthDate);
    on<SetConsent>(_onSetConsent);
    on<SetGoals>(_onSetGoals);
    on<SetPeriodComfort>(_onSetPeriodComfort);
    on<SetPeriodStatus>(_onSetPeriodStatus);
    on<SetInterestTopics>(_onSetInterestTopics);
    on<SetAvatar>(_onSetAvatar);
    on<SetJourneyName>(_onSetJourneyName);
    on<SetTrackerDetails>(_onSetTrackerDetails);
    on<AddPoints>(_onAddPoints);
    on<SubmitRegistration>(_onSubmitRegistration);
    on<SubmitPersonalization>(_onSubmitPersonalization);
    on<SubmitAvatar>(_onSubmitAvatar);
    on<SubmitJourneyName>(_onSubmitJourneyName);
    on<SubmitTrackerSetup>(_onSubmitTrackerSetup);
    on<SyncFromStorage>(_onSyncFromStorage);
  }

  void _onSetUserType(SetUserType e, Emitter<OnboardingState> emit) {
    _storage.setUserType(e.t);
    _storage.setStageComplete('1');
    _repo.updateStage(1);
    emit(state.copyWith(userType: e.t));
  }

  void _onSetDisplayName(SetDisplayName e, Emitter<OnboardingState> emit) {
    _storage.setDisplayName(e.name);
    _storage.setPronouns(e.pronouns);
    _storage.setStageComplete('2');
    _repo.updateStage(2);
    emit(state.copyWith(displayName: e.name, pronouns: e.pronouns));
  }

  void _onSetPhone(SetPhone e, Emitter<OnboardingState> emit) {
    _storage.setPhone(e.phone);
    emit(state.copyWith(phone: e.phone));
  }

  void _onSetBirthDate(SetBirthDate e, Emitter<OnboardingState> emit) {
    final now = DateTime.now();
    int age = now.year - e.year;
    if (now.month < e.month) age--;
    final tier = age < 13 ? 'JUNIOR' : age < 16 ? 'TEEN_EARLY' : age < 18 ? 'TEEN_LATE' : 'ADULT';
    emit(state.copyWith(birthMonth: e.month, birthYear: e.year, age: age, contentTier: tier, coppaRequired: age < 13));
    _storage.setBirthDate(e.month, e.year);
    _storage.setStageComplete('3');
    _repo.updateStage(3);
  }

  void _onSetConsent(SetConsent e, Emitter<OnboardingState> emit) {
    emit(state.copyWith(termsAccepted: e.terms, privacyAccepted: e.privacy, marketingOptIn: e.marketing));
    _storage.setConsents(terms: e.terms, privacy: e.privacy, marketing: e.marketing);
    _storage.setStageComplete('4'); 
    _repo.updateStage(4);
  }

  void _onSetGoals(SetGoals e, Emitter<OnboardingState> emit) {
    _storage.setStageComplete('5');
    _repo.updateStage(5);
    emit(state.copyWith(goals: e.goals));
  }
  void _onSetPeriodComfort(SetPeriodComfort e, Emitter<OnboardingState> emit) {
    _storage.setStageComplete('6');
    _repo.updateStage(6);
    emit(state.copyWith(periodComfortScore: e.score));
  }
  void _onSetPeriodStatus(SetPeriodStatus e, Emitter<OnboardingState> emit) {
    _storage.setStageComplete('7');
    _repo.updateStage(7);
    emit(state.copyWith(periodStatus: e.status));
  }
  void _onSetInterestTopics(SetInterestTopics e, Emitter<OnboardingState> emit) {
    _storage.setStageComplete('8');
    _repo.updateStage(8);
    emit(state.copyWith(interestTopics: e.topics));
  }
  void _onSetAvatar(SetAvatar e, Emitter<OnboardingState> emit) {
    _storage.setStageComplete('9');
    _repo.updateStage(9);
    emit(state.copyWith(avatarData: e.data));
  }
  void _onSetJourneyName(SetJourneyName e, Emitter<OnboardingState> emit) {
    _storage.setStageComplete('10');
    _repo.updateStage(10);
    emit(state.copyWith(journeyName: e.name));
  }
  void _onSetTrackerDetails(SetTrackerDetails e, Emitter<OnboardingState> emit) {
    _storage.setStageComplete('12');
    _repo.updateStage(12);
    emit(state.copyWith(periodLength: e.periodDays, cycleLength: e.cycleDays, lastPeriod: e.lastPeriod));
  }
  
  void _onAddPoints(AddPoints e, Emitter<OnboardingState> emit) {
    final newTotal = state.totalPoints + e.points;
    _storage.setPoints(newTotal);
    emit(state.copyWith(totalPoints: newTotal));
  }

  Future<void> _onSubmitRegistration(SubmitRegistration e, Emitter<OnboardingState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final result = await _repo.register(
        tempToken:       e.tempToken,
        displayName:     state.displayName,
        birthMonth:      state.birthMonth,
        birthYear:       state.birthYear,
        termsAccepted:   state.termsAccepted,
        privacyAccepted: state.privacyAccepted,
        marketingOptIn:  state.marketingOptIn,
      );
      
      await _storage.setAuthToken(result['accessToken']);
      await _storage.setRefreshToken(result['refreshToken']);
      await _storage.setUserId(result['userId']);
      await _storage.setStageComplete(result['onboardingStage'].toString());
      
      emit(state.copyWith(isLoading: false, errorMessage: null));
    } catch (err) {
      final errorStr = err.toString();
      final isExpired = errorStr.contains('Session expired');
      if (isExpired) await _storage.clearTempToken();
      emit(state.copyWith(isLoading: false, errorMessage: errorStr, sessionExpired: isExpired));
    }
  }

  Future<void> _onSubmitPersonalization(SubmitPersonalization e, Emitter<OnboardingState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final res = await _repo.savePersonalization(
        goals: state.goals,
        periodComfortScore: state.periodComfortScore,
        periodStatus: state.periodStatus,
        interestTopics: state.interestTopics,
      );
      await _storage.setPoints(res['pointsTotal']);
      await _storage.setStageComplete('3');
      emit(state.copyWith(isLoading: false, totalPoints: res['pointsTotal']));
    } catch (err) {
      emit(state.copyWith(isLoading: false, errorMessage: err.toString()));
    }
  }

  Future<void> _onSubmitAvatar(SubmitAvatar e, Emitter<OnboardingState> emit) async {
    if (state.avatarData.isEmpty) return;
    emit(state.copyWith(isLoading: true));
    try {
      await _repo.saveAvatar(state.avatarData);
      await _storage.setStageComplete('4');
      emit(state.copyWith(isLoading: false));
    } catch (err) {
      emit(state.copyWith(isLoading: false, errorMessage: err.toString()));
    }
  }

  Future<void> _onSubmitJourneyName(SubmitJourneyName e, Emitter<OnboardingState> emit) async {
    if (state.journeyName.isEmpty) return;
    emit(state.copyWith(isLoading: true));
    try {
      final res = await _repo.saveJourneyName(state.journeyName);
      await _storage.setPoints(res['pointsTotal']);
      await _storage.setStageComplete('4.1');
      emit(state.copyWith(isLoading: false, totalPoints: res['pointsTotal']));
    } catch (err) {
      emit(state.copyWith(isLoading: false, errorMessage: err.toString()));
    }
  }

  Future<void> _onSubmitTrackerSetup(SubmitTrackerSetup e, Emitter<OnboardingState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _repo.trackerSetup(
        lastPeriodStart:  state.lastPeriod?.toIso8601String(),
        periodLengthDays: state.periodLength,
        cycleLengthDays:  state.cycleLength,
      );
      await _repo.completeOnboarding();
      await _storage.setStageComplete('13');
      _repo.updateStage(13);
      emit(state.copyWith(isLoading: false, errorMessage: null));
    } catch (err) {
      emit(state.copyWith(isLoading: false, errorMessage: err.toString()));
    }
  }

  void _onSyncFromStorage(SyncFromStorage e, Emitter<OnboardingState> emit) {
    emit(state.copyWith(
      userType:    _storage.userType ?? state.userType,
      displayName: _storage.displayName ?? state.displayName,
      pronouns:    _storage.pronouns ?? state.pronouns,
      phone:       _storage.phone ?? state.phone,
      birthMonth:  _storage.birthMonth ?? state.birthMonth,
      birthYear:   _storage.birthYear ?? state.birthYear,
      termsAccepted: _storage.termsAccepted,
      privacyAccepted: _storage.privacyAccepted,
      marketingOptIn: _storage.marketingOptIn,
      totalPoints: _storage.points,
    ));
  }
}
