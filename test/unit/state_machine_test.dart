import 'package:flutter_permission_wizard/src/state/permission_state_machine.dart';
import 'package:flutter_permission_wizard/src/state/wizard_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PermissionStateMachine', () {
    test('starts in idle', () {
      final fsm = PermissionStateMachine();
      expect(fsm.phase, WizardPhase.idle);
      expect(fsm.isTerminal, isFalse);
    });

    test('idle → checkingStatus on start', () {
      final fsm = PermissionStateMachine();
      fsm.transition(WizardEvent.start);
      expect(fsm.phase, WizardPhase.checkingStatus);
    });

    test('checkingStatus → granted', () {
      final fsm = PermissionStateMachine()..transition(WizardEvent.start);
      fsm.transition(WizardEvent.statusGranted);
      expect(fsm.phase, WizardPhase.granted);
      expect(fsm.isTerminal, isTrue);
    });

    test('checkingStatus → restricted', () {
      final fsm = PermissionStateMachine()..transition(WizardEvent.start);
      fsm.transition(WizardEvent.statusRestricted);
      expect(fsm.phase, WizardPhase.restricted);
      expect(fsm.isTerminal, isTrue);
    });

    test('full happy path: rationale → allow → granted', () {
      final fsm = PermissionStateMachine();
      fsm.transition(WizardEvent.start);
      fsm.transition(WizardEvent.needsRequest);
      expect(fsm.phase, WizardPhase.showingRationale);
      fsm.transition(WizardEvent.rationaleAllow);
      expect(fsm.phase, WizardPhase.requestingOs);
      fsm.transition(WizardEvent.osGranted);
      expect(fsm.phase, WizardPhase.granted);
    });

    test('rationale denied → cancelled', () {
      final fsm = PermissionStateMachine();
      fsm.transition(WizardEvent.start);
      fsm.transition(WizardEvent.needsRequest);
      fsm.transition(WizardEvent.rationaleDeny);
      expect(fsm.phase, WizardPhase.cancelled);
      expect(fsm.isTerminal, isTrue);
    });

    test('soft denial loops back through rationale on retry', () {
      final fsm = PermissionStateMachine(maxRetryAttempts: 1);
      fsm.transition(WizardEvent.start);
      fsm.transition(WizardEvent.needsRequest);
      fsm.transition(WizardEvent.rationaleAllow);
      fsm.transition(WizardEvent.osDeniedSoft);
      expect(fsm.phase, WizardPhase.deniedSoft);
      fsm.transition(WizardEvent.retry);
      expect(fsm.phase, WizardPhase.showingRationale);
      expect(fsm.retryCount, 1);
    });

    test('soft denial exceeds retry budget → cancelled', () {
      final fsm = PermissionStateMachine(maxRetryAttempts: 1);
      fsm.transition(WizardEvent.start);
      fsm.transition(WizardEvent.needsRequest);
      fsm.transition(WizardEvent.rationaleAllow);
      // First denial inside the budget.
      fsm.transition(WizardEvent.osDeniedSoft);
      fsm.transition(WizardEvent.retry); // retryCount becomes 1
      // Loop back into request and exceed budget on second denial.
      fsm.transition(WizardEvent.rationaleAllow);
      final next = fsm.transition(WizardEvent.osDeniedSoft);
      expect(next, WizardPhase.cancelled);
    });

    test('permanent denial → openSettings → awaitingResume → recheck', () {
      final fsm = PermissionStateMachine();
      fsm.transition(WizardEvent.start);
      fsm.transition(WizardEvent.needsRequest);
      fsm.transition(WizardEvent.rationaleAllow);
      fsm.transition(WizardEvent.osDeniedPermanent);
      expect(fsm.phase, WizardPhase.deniedPermanent);
      // First openSettings: deniedPermanent → openingSettings.
      fsm.transition(WizardEvent.openSettings);
      expect(fsm.phase, WizardPhase.openingSettings);
      // Second openSettings: openingSettings → awaitingResume (sets
      // hasOpenedSettings as a side effect).
      fsm.transition(WizardEvent.openSettings);
      expect(fsm.phase, WizardPhase.awaitingResume);
      expect(fsm.hasOpenedSettings, isTrue);
      fsm.transition(WizardEvent.resumedFromSettings);
      expect(fsm.phase, WizardPhase.checkingStatus);
      fsm.transition(WizardEvent.statusGranted);
      expect(fsm.phase, WizardPhase.granted);
    });

    test('app backgrounded while showing rationale → cancelled', () {
      final fsm = PermissionStateMachine();
      fsm.transition(WizardEvent.start);
      fsm.transition(WizardEvent.needsRequest);
      fsm.transition(WizardEvent.appBackgrounded);
      expect(fsm.phase, WizardPhase.cancelled);
    });

    test('skipRationale fast-forwards to requestingOs', () {
      final fsm = PermissionStateMachine();
      fsm.transition(WizardEvent.start);
      fsm.transition(WizardEvent.needsRequest);
      fsm.skipRationale();
      expect(fsm.phase, WizardPhase.requestingOs);
    });

    test('invalid transitions throw', () {
      final fsm = PermissionStateMachine();
      expect(
        () => fsm.transition(WizardEvent.osGranted),
        throwsA(isA<StateError>()),
      );
    });

    test('terminal phases reject all further events', () {
      final fsm = PermissionStateMachine();
      fsm.transition(WizardEvent.start);
      fsm.transition(WizardEvent.statusGranted);
      expect(
        () => fsm.transition(WizardEvent.start),
        throwsA(isA<StateError>()),
      );
    });

    test('history records every transition', () {
      final fsm = PermissionStateMachine();
      expect(fsm.history.length, 1); // initial snapshot
      fsm.transition(WizardEvent.start);
      fsm.transition(WizardEvent.statusGranted);
      expect(fsm.history.length, 3);
      expect(fsm.history.last.phase, WizardPhase.granted);
    });

    test('statusForPhase maps phases correctly', () {
      expect(
        PermissionStateMachine.statusForPhase(WizardPhase.idle),
        WizardStatus.initial,
      );
      expect(
        PermissionStateMachine.statusForPhase(WizardPhase.checkingStatus),
        WizardStatus.checking,
      );
      expect(
        PermissionStateMachine.statusForPhase(WizardPhase.granted),
        WizardStatus.granted,
      );
      expect(
        PermissionStateMachine.statusForPhase(WizardPhase.limited),
        WizardStatus.limited,
      );
      expect(
        PermissionStateMachine.statusForPhase(WizardPhase.deniedSoft),
        WizardStatus.denied,
      );
      expect(
        PermissionStateMachine.statusForPhase(WizardPhase.deniedPermanent),
        WizardStatus.denied,
      );
      expect(
        PermissionStateMachine.statusForPhase(WizardPhase.restricted),
        WizardStatus.restricted,
      );
      expect(
        PermissionStateMachine.statusForPhase(WizardPhase.cancelled),
        WizardStatus.cancelled,
      );
      expect(
        PermissionStateMachine.statusForPhase(WizardPhase.showingRationale),
        WizardStatus.inProgress,
      );
      expect(
        PermissionStateMachine.statusForPhase(WizardPhase.openingSettings),
        WizardStatus.inProgress,
      );
    });
  });
}
