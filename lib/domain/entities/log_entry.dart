class LogEntry {
  final int? id;
  final String? usuario;
  final String acao;
  final String? dataLog;

  LogEntry({
    this.id,
    this.usuario,
    required this.acao,
    this.dataLog,
  });

  factory LogEntry.fromMap(Map<String, dynamic> map) {
    return LogEntry(
      id: map['id'] as int?,
      usuario: map['usuario'] as String?,
      acao: map['acao'] as String,
      dataLog: map['data_log'] as String?,
    );
  }
}
