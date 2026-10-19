import 'dart:math';
import 'package:gelir_gider_uygulamasi/models/group/group_expense.dart';
import 'package:gelir_gider_uygulamasi/models/group/group_settlement.dart';
import 'package:gelir_gider_uygulamasi/models/group/participant.dart';

class ExpenseGroup {
  final String id;
  final String title;
  final List<Participant> participants;
  final List<GroupExpense> expenses;
  final DateTime createdAt;
  final String? icon;

  const ExpenseGroup({
    required this.id,
    required this.title,
    required this.participants,
    required this.expenses,
    required this.createdAt,
    this.icon,
  });

  /// Gruptaki mevcut kullanıcı
  Participant? get currentUser {
    try {
      return participants.firstWhere((p) => p.isCurrentUser);
    } catch (_) {
      return participants.isNotEmpty ? participants.first : null;
    }
  }

  /// Katılımcıyı ID'ye göre bulma
  Participant? findParticipant(String id) {
    try {
      return participants.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Katılımcı adı ("Sen" veya isim)
  String participantName(String id) {
    return findParticipant(id)?.displayName ?? 'Bilinmeyen';
  }

  /// Gruptaki toplam harcama tutarı
  double get totalExpense {
    return expenses.fold<double>(0.0, (sum, exp) => sum + exp.amount);
  }

  /// Katılımcı başına net bakiye:
  /// (Ödediği Toplam Tutar) - (Kendi Payına Düşen Harcama)
  /// Pozitif: Alacaklı, Negatif: Borçlu
  Map<String, double> get participantBalances {
    final balances = <String, double>{};
    for (final p in participants) {
      balances[p.id] = 0.0;
    }

    for (final expense in expenses) {
      // Ödeyen kişiye ödediği tutar alacak olarak eklenir
      balances[expense.paidById] =
          (balances[expense.paidById] ?? 0.0) + expense.amount;

      // Harcamayı paylaşan her kişiden kendi payı düşülür
      final perPerson = expense.perPersonAmount;
      for (final splitId in expense.splitParticipantIds) {
        balances[splitId] = (balances[splitId] ?? 0.0) - perPerson;
      }
    }

    return balances;
  }

  /// Giriş yapan kullanıcının bu gruptaki net bakiyesi
  double get userNetBalance {
    final user = currentUser;
    if (user == null) return 0.0;
    return participantBalances[user.id] ?? 0.0;
  }

  /// Borç sadeleştirme algoritması (Debt Simplification)
  /// Pozitif bakiyeliler (alacaklılar) ile negatif bakiyelileri (borçlular)
  /// greedy şekilde eşleştirerek en az sayıda transfer listesi döndürür.
  List<GroupSettlement> calculateSettlements() {
    final balances = participantBalances;
    final settlements = <GroupSettlement>[];

    // Alacaklılar (pozitif) ve borçlular (negatif)
    // Listelerin elemanları: [participantId, balance]
    final creditors = <_BalanceEntry>[];
    final debtors = <_BalanceEntry>[];

    balances.forEach((id, balance) {
      // 1 kuruştan küçük sapmaları yuvarla (floating point hatasını önle)
      if (balance > 0.01) {
        creditors.add(_BalanceEntry(id, balance));
      } else if (balance < -0.01) {
        debtors.add(_BalanceEntry(id, -balance)); // pozitif borç tutarı olarak sakla
      }
    });

    // En büyükten en küçüğe sırala (greedy yaklaşım)
    creditors.sort((a, b) => b.amount.compareTo(a.amount));
    debtors.sort((a, b) => b.amount.compareTo(a.amount));

    int cIndex = 0;
    int dIndex = 0;

    while (cIndex < creditors.length && dIndex < debtors.length) {
      final creditor = creditors[cIndex];
      final debtor = debtors[dIndex];

      final settlementAmount = min(creditor.amount, debtor.amount);

      if (settlementAmount > 0.01) {
        settlements.add(
          GroupSettlement(
            fromParticipantId: debtor.id,
            toParticipantId: creditor.id,
            amount: double.parse(settlementAmount.toStringAsFixed(2)),
          ),
        );
      }

      creditor.amount -= settlementAmount;
      debtor.amount -= settlementAmount;

      if (creditor.amount < 0.01) {
        cIndex++;
      }
      if (debtor.amount < 0.01) {
        dIndex++;
      }
    }

    return settlements;
  }

  ExpenseGroup copyWith({
    String? id,
    String? title,
    List<Participant>? participants,
    List<GroupExpense>? expenses,
    DateTime? createdAt,
    String? icon,
  }) {
    return ExpenseGroup(
      id: id ?? this.id,
      title: title ?? this.title,
      participants: participants ?? this.participants,
      expenses: expenses ?? this.expenses,
      createdAt: createdAt ?? this.createdAt,
      icon: icon ?? this.icon,
    );
  }

  factory ExpenseGroup.fromJson(Map<String, dynamic> json) {
    return ExpenseGroup(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      participants: (json['participants'] as List?)
              ?.map((p) => Participant.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      expenses: (json['expenses'] as List?)
              ?.map((e) => GroupExpense.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      icon: json['icon']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'participants': participants.map((p) => p.toJson()).toList(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        if (icon != null) 'icon': icon,
      };
}

class _BalanceEntry {
  final String id;
  double amount;
  _BalanceEntry(this.id, this.amount);
}
