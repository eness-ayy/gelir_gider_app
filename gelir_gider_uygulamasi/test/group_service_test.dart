import 'package:flutter_test/flutter_test.dart';
import 'package:gelir_gider_uygulamasi/models/group/expense_group.dart';
import 'package:gelir_gider_uygulamasi/models/group/group_expense.dart';
import 'package:gelir_gider_uygulamasi/models/group/participant.dart';

void main() {
  group('ExpenseGroup Debt Simplification & Balance Calculation Tests', () {
    test('Calculates equal split balances correctly for simple case', () {
      final pMe = const Participant(id: 'me', name: 'Ben', isCurrentUser: true);
      final pAli = const Participant(id: 'ali', name: 'Ali');
      final pAyse = const Participant(id: 'ayse', name: 'Ayşe');
      final pVeli = const Participant(id: 'veli', name: 'Veli');

      // 4 kişi var. Ben 1200 TL ödedim, 4 kişi eşit paylaştı. (Kişi başı 300 TL)
      final group = ExpenseGroup(
        id: 'grp_1',
        title: 'Hafta Sonu',
        participants: [pMe, pAli, pAyse, pVeli],
        createdAt: DateTime.now(),
        expenses: [
          GroupExpense(
            id: 'e1',
            title: 'Konaklama',
            amount: 1200.0,
            paidById: 'me',
            date: DateTime.now(),
            splitParticipantIds: ['me', 'ali', 'ayse', 'veli'],
          ),
        ],
      );

      final balances = group.participantBalances;
      expect(balances['me'], equals(900.0)); // 1200 - 300 = +900 (Alacaklı)
      expect(balances['ali'], equals(-300.0)); // 0 - 300 = -300 (Borçlu)
      expect(balances['ayse'], equals(-300.0));
      expect(balances['veli'], equals(-300.0));

      expect(group.userNetBalance, equals(900.0));

      final settlements = group.calculateSettlements();
      expect(settlements.length, equals(3));
      // Ali, Ayşe ve Veli hepsi 'me' ye 300 TL ödemeli
      for (final s in settlements) {
        expect(s.toParticipantId, equals('me'));
        expect(s.amount, equals(300.0));
      }
    });

    test('Simplifies complex circular debts into minimal transactions', () {
      final pA = const Participant(id: 'A', name: 'Ahmet');
      final pB = const Participant(id: 'B', name: 'Burak');
      final pC = const Participant(id: 'C', name: 'Cem');

      // A 300 TL ödedi (A, B, C bölüştü -> kişi başı 100)
      // B 150 TL ödedi (B, C bölüştü -> kişi başı 75)
      // Net bakiyeler:
      // A: +300 - 100 = +200
      // B: +150 - 100 - 75 = -25
      // C: 0 - 100 - 75 = -175
      // Toplam: +200 - 25 - 175 = 0
      final group = ExpenseGroup(
        id: 'grp_complex',
        title: 'Tatil',
        participants: [pA, pB, pC],
        createdAt: DateTime.now(),
        expenses: [
          GroupExpense(
            id: 'e1',
            title: 'Yemek',
            amount: 300.0,
            paidById: 'A',
            date: DateTime.now(),
            splitParticipantIds: ['A', 'B', 'C'],
          ),
          GroupExpense(
            id: 'e2',
            title: 'Taksi',
            amount: 150.0,
            paidById: 'B',
            date: DateTime.now(),
            splitParticipantIds: ['B', 'C'],
          ),
        ],
      );

      final balances = group.participantBalances;
      expect(balances['A'], equals(200.0));
      expect(balances['B'], equals(-25.0));
      expect(balances['C'], equals(-175.0));

      final settlements = group.calculateSettlements();
      // Borçlular (C: 175, B: 25) doğrudan A'ya (200) öder. En az transfer: 2 adet!
      expect(settlements.length, equals(2));

      final cSettlement =
          settlements.firstWhere((s) => s.fromParticipantId == 'C');
      expect(cSettlement.toParticipantId, equals('A'));
      expect(cSettlement.amount, equals(175.0));

      final bSettlement =
          settlements.firstWhere((s) => s.fromParticipantId == 'B');
      expect(bSettlement.toParticipantId, equals('A'));
      expect(bSettlement.amount, equals(25.0));
    });

    test('Participant and GroupExpense JSON serialization roundtrip', () {
      final p = const Participant(id: 'p1', name: 'Deniz', isCurrentUser: true);
      final pJson = p.toJson();
      final pRestored = Participant.fromJson(pJson);
      expect(pRestored.id, equals(p.id));
      expect(pRestored.name, equals(p.name));
      expect(pRestored.isCurrentUser, isTrue);

      final exp = GroupExpense(
        id: 'e1',
        title: 'Test',
        amount: 250.50,
        paidById: 'p1',
        date: DateTime(2026, 5, 10, 14, 30),
        splitParticipantIds: ['p1', 'p2'],
        paymentMethod: 'bank_card',
      );
      final expJson = exp.toJson();
      final expRestored = GroupExpense.fromJson(expJson);
      expect(expRestored.id, equals(exp.id));
      expect(expRestored.amount, equals(250.50));
      expect(expRestored.paymentMethod, equals('bank_card'));
      expect(expRestored.perPersonAmount, equals(125.25));
    });
  });
}
