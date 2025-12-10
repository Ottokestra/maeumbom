import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

/// TB_ALARMS 테이블 정의
/// 백엔드 DB 규칙 준수: TB_ 접두사, 대문자 컬럼명, 표준 필드 포함
@DataClassName('AlarmData')
class Alarms extends Table {
  @override
  String get tableName => 'TB_ALARMS';

  // Primary Key
  IntColumn get id => integer().autoIncrement()();

  // 알람 시간 정보
  IntColumn get year => integer()();
  IntColumn get month => integer()();
  IntColumn get day => integer()();
  TextColumn get week => text()(); // JSON 배열 문자열: ["Monday", "Tuesday"]
  IntColumn get time => integer()(); // 12시간 형식 (1-12)
  IntColumn get minute => integer()();
  TextColumn get amPm => text().withLength(min: 2, max: 2)(); // 'am' | 'pm'

  // 알람 상태
  BoolColumn get isValid => boolean()(); // 유효한 알람인지 (과거 시간 체크)
  BoolColumn get isEnabled =>
      boolean().withDefault(const Constant(true))(); // 사용자 ON/OFF

  // 푸시 알림 ID
  IntColumn get notificationId =>
      integer()(); // flutter_local_notifications용 고유 ID

  // 계산된 스케줄 시간
  DateTimeColumn get scheduledDatetime => dateTime()(); // 실제 알람 발송 시간

  // 알람 제목/내용 (백엔드에서 제공 예정)
  TextColumn get title => text().nullable()();
  TextColumn get content => text().nullable()();

  // 표준 필드 (백엔드 규칙 준수)
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get createdBy => integer().nullable()(); // USER_ID (로그인 사용자)
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get updatedBy => integer().nullable()(); // USER_ID

  @override
  List<String> get customConstraints => [
        'UNIQUE(notification_id)',
      ];
}

/// Drift 데이터베이스 클래스
@DriftDatabase(tables: [Alarms])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // 알람 조회 (삭제되지 않은 것만)
  Future<List<AlarmData>> getAllAlarms() {
    return (select(alarms)
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledDatetime)]))
        .get();
  }

  // 활성화된 알람만 조회
  Future<List<AlarmData>> getEnabledAlarms() {
    return (select(alarms)
          ..where(
              (tbl) => tbl.isDeleted.equals(false) & tbl.isEnabled.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledDatetime)]))
        .get();
  }

  // 특정 알람 조회
  Future<AlarmData?> getAlarmById(int id) {
    return (select(alarms)
          ..where((tbl) => tbl.id.equals(id) & tbl.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  // 알람 삽입
  Future<int> insertAlarm(AlarmsCompanion alarm) {
    return into(alarms).insert(alarm);
  }

  // 알람 수정
  Future<int> updateAlarm(int id, AlarmsCompanion alarm) {
    return (update(alarms)..where((tbl) => tbl.id.equals(id))).write(alarm);
  }

  // 알람 삭제 (소프트 삭제)
  Future<int> deleteAlarm(int id, {int? userId}) {
    return (update(alarms)..where((tbl) => tbl.id.equals(id))).write(
      AlarmsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
        updatedBy: Value(userId),
      ),
    );
  }
}

/// DB 연결 설정
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'maeumbom.db'));
    return NativeDatabase(file);
  });
}
