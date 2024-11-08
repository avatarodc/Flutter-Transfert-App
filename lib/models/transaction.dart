class Transaction {
  final String date;
  final String amount;
  final String type;
  final String recipient;
  final String status;

  const Transaction({
    required this.date,
    required this.amount,
    required this.type,
    required this.recipient,
    required this.status,
  });
}