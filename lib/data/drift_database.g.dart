// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drift_database.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
      'local_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _usernameMeta =
      const VerificationMeta('username');
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
      'username', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isCoachMeta =
      const VerificationMeta('isCoach');
  @override
  late final GeneratedColumn<bool> isCoach = GeneratedColumn<bool>(
      'is_coach', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_coach" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _visibilityMeta =
      const VerificationMeta('visibility');
  @override
  late final GeneratedColumn<String> visibility = GeneratedColumn<String>(
      'visibility', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('private'));
  static const VerificationMeta _birthdayMeta =
      const VerificationMeta('birthday');
  @override
  late final GeneratedColumn<DateTime> birthday = GeneratedColumn<DateTime>(
      'birthday', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
      'height', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
      'gender', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _profileImagePathMeta =
      const VerificationMeta('profileImagePath');
  @override
  late final GeneratedColumn<String> profileImagePath = GeneratedColumn<String>(
      'profile_image_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        id,
        createdAt,
        updatedAt,
        deletedAt,
        username,
        isCoach,
        visibility,
        birthday,
        height,
        gender,
        profileImagePath
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(Insertable<Profile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('username')) {
      context.handle(_usernameMeta,
          username.isAcceptableOrUnknown(data['username']!, _usernameMeta));
    }
    if (data.containsKey('is_coach')) {
      context.handle(_isCoachMeta,
          isCoach.isAcceptableOrUnknown(data['is_coach']!, _isCoachMeta));
    }
    if (data.containsKey('visibility')) {
      context.handle(
          _visibilityMeta,
          visibility.isAcceptableOrUnknown(
              data['visibility']!, _visibilityMeta));
    }
    if (data.containsKey('birthday')) {
      context.handle(_birthdayMeta,
          birthday.isAcceptableOrUnknown(data['birthday']!, _birthdayMeta));
    }
    if (data.containsKey('height')) {
      context.handle(_heightMeta,
          height.isAcceptableOrUnknown(data['height']!, _heightMeta));
    }
    if (data.containsKey('gender')) {
      context.handle(_genderMeta,
          gender.isAcceptableOrUnknown(data['gender']!, _genderMeta));
    }
    if (data.containsKey('profile_image_path')) {
      context.handle(
          _profileImagePathMeta,
          profileImagePath.isAcceptableOrUnknown(
              data['profile_image_path']!, _profileImagePathMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}local_id'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      username: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}username']),
      isCoach: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_coach'])!,
      visibility: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}visibility'])!,
      birthday: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}birthday']),
      height: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}height']),
      gender: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gender']),
      profileImagePath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}profile_image_path']),
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class Profile extends DataClass implements Insertable<Profile> {
  final int localId;
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? username;
  final bool isCoach;
  final String visibility;
  final DateTime? birthday;
  final int? height;
  final String? gender;
  final String? profileImagePath;
  const Profile(
      {required this.localId,
      required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      this.username,
      required this.isCoach,
      required this.visibility,
      this.birthday,
      this.height,
      this.gender,
      this.profileImagePath});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || username != null) {
      map['username'] = Variable<String>(username);
    }
    map['is_coach'] = Variable<bool>(isCoach);
    map['visibility'] = Variable<String>(visibility);
    if (!nullToAbsent || birthday != null) {
      map['birthday'] = Variable<DateTime>(birthday);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    if (!nullToAbsent || gender != null) {
      map['gender'] = Variable<String>(gender);
    }
    if (!nullToAbsent || profileImagePath != null) {
      map['profile_image_path'] = Variable<String>(profileImagePath);
    }
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      localId: Value(localId),
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      username: username == null && nullToAbsent
          ? const Value.absent()
          : Value(username),
      isCoach: Value(isCoach),
      visibility: Value(visibility),
      birthday: birthday == null && nullToAbsent
          ? const Value.absent()
          : Value(birthday),
      height:
          height == null && nullToAbsent ? const Value.absent() : Value(height),
      gender:
          gender == null && nullToAbsent ? const Value.absent() : Value(gender),
      profileImagePath: profileImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(profileImagePath),
    );
  }

  factory Profile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      localId: serializer.fromJson<int>(json['localId']),
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      username: serializer.fromJson<String?>(json['username']),
      isCoach: serializer.fromJson<bool>(json['isCoach']),
      visibility: serializer.fromJson<String>(json['visibility']),
      birthday: serializer.fromJson<DateTime?>(json['birthday']),
      height: serializer.fromJson<int?>(json['height']),
      gender: serializer.fromJson<String?>(json['gender']),
      profileImagePath: serializer.fromJson<String?>(json['profileImagePath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'username': serializer.toJson<String?>(username),
      'isCoach': serializer.toJson<bool>(isCoach),
      'visibility': serializer.toJson<String>(visibility),
      'birthday': serializer.toJson<DateTime?>(birthday),
      'height': serializer.toJson<int?>(height),
      'gender': serializer.toJson<String?>(gender),
      'profileImagePath': serializer.toJson<String?>(profileImagePath),
    };
  }

  Profile copyWith(
          {int? localId,
          String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          Value<String?> username = const Value.absent(),
          bool? isCoach,
          String? visibility,
          Value<DateTime?> birthday = const Value.absent(),
          Value<int?> height = const Value.absent(),
          Value<String?> gender = const Value.absent(),
          Value<String?> profileImagePath = const Value.absent()}) =>
      Profile(
        localId: localId ?? this.localId,
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        username: username.present ? username.value : this.username,
        isCoach: isCoach ?? this.isCoach,
        visibility: visibility ?? this.visibility,
        birthday: birthday.present ? birthday.value : this.birthday,
        height: height.present ? height.value : this.height,
        gender: gender.present ? gender.value : this.gender,
        profileImagePath: profileImagePath.present
            ? profileImagePath.value
            : this.profileImagePath,
      );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      localId: data.localId.present ? data.localId.value : this.localId,
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      username: data.username.present ? data.username.value : this.username,
      isCoach: data.isCoach.present ? data.isCoach.value : this.isCoach,
      visibility:
          data.visibility.present ? data.visibility.value : this.visibility,
      birthday: data.birthday.present ? data.birthday.value : this.birthday,
      height: data.height.present ? data.height.value : this.height,
      gender: data.gender.present ? data.gender.value : this.gender,
      profileImagePath: data.profileImagePath.present
          ? data.profileImagePath.value
          : this.profileImagePath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('username: $username, ')
          ..write('isCoach: $isCoach, ')
          ..write('visibility: $visibility, ')
          ..write('birthday: $birthday, ')
          ..write('height: $height, ')
          ..write('gender: $gender, ')
          ..write('profileImagePath: $profileImagePath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      localId,
      id,
      createdAt,
      updatedAt,
      deletedAt,
      username,
      isCoach,
      visibility,
      birthday,
      height,
      gender,
      profileImagePath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.localId == this.localId &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.username == this.username &&
          other.isCoach == this.isCoach &&
          other.visibility == this.visibility &&
          other.birthday == this.birthday &&
          other.height == this.height &&
          other.gender == this.gender &&
          other.profileImagePath == this.profileImagePath);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<int> localId;
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> username;
  final Value<bool> isCoach;
  final Value<String> visibility;
  final Value<DateTime?> birthday;
  final Value<int?> height;
  final Value<String?> gender;
  final Value<String?> profileImagePath;
  const ProfilesCompanion({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.username = const Value.absent(),
    this.isCoach = const Value.absent(),
    this.visibility = const Value.absent(),
    this.birthday = const Value.absent(),
    this.height = const Value.absent(),
    this.gender = const Value.absent(),
    this.profileImagePath = const Value.absent(),
  });
  ProfilesCompanion.insert({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.username = const Value.absent(),
    this.isCoach = const Value.absent(),
    this.visibility = const Value.absent(),
    this.birthday = const Value.absent(),
    this.height = const Value.absent(),
    this.gender = const Value.absent(),
    this.profileImagePath = const Value.absent(),
  });
  static Insertable<Profile> custom({
    Expression<int>? localId,
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? username,
    Expression<bool>? isCoach,
    Expression<String>? visibility,
    Expression<DateTime>? birthday,
    Expression<int>? height,
    Expression<String>? gender,
    Expression<String>? profileImagePath,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (username != null) 'username': username,
      if (isCoach != null) 'is_coach': isCoach,
      if (visibility != null) 'visibility': visibility,
      if (birthday != null) 'birthday': birthday,
      if (height != null) 'height': height,
      if (gender != null) 'gender': gender,
      if (profileImagePath != null) 'profile_image_path': profileImagePath,
    });
  }

  ProfilesCompanion copyWith(
      {Value<int>? localId,
      Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String?>? username,
      Value<bool>? isCoach,
      Value<String>? visibility,
      Value<DateTime?>? birthday,
      Value<int?>? height,
      Value<String?>? gender,
      Value<String?>? profileImagePath}) {
    return ProfilesCompanion(
      localId: localId ?? this.localId,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      username: username ?? this.username,
      isCoach: isCoach ?? this.isCoach,
      visibility: visibility ?? this.visibility,
      birthday: birthday ?? this.birthday,
      height: height ?? this.height,
      gender: gender ?? this.gender,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (isCoach.present) {
      map['is_coach'] = Variable<bool>(isCoach.value);
    }
    if (visibility.present) {
      map['visibility'] = Variable<String>(visibility.value);
    }
    if (birthday.present) {
      map['birthday'] = Variable<DateTime>(birthday.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (profileImagePath.present) {
      map['profile_image_path'] = Variable<String>(profileImagePath.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('username: $username, ')
          ..write('isCoach: $isCoach, ')
          ..write('visibility: $visibility, ')
          ..write('birthday: $birthday, ')
          ..write('height: $height, ')
          ..write('gender: $gender, ')
          ..write('profileImagePath: $profileImagePath')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
      'local_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES profiles (id)'));
  static const VerificationMeta _themeModeMeta =
      const VerificationMeta('themeMode');
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
      'theme_mode', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('system'));
  static const VerificationMeta _unitSystemMeta =
      const VerificationMeta('unitSystem');
  @override
  late final GeneratedColumn<String> unitSystem = GeneratedColumn<String>(
      'unit_system', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('metric'));
  static const VerificationMeta _targetCaloriesMeta =
      const VerificationMeta('targetCalories');
  @override
  late final GeneratedColumn<int> targetCalories = GeneratedColumn<int>(
      'target_calories', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(2500));
  static const VerificationMeta _targetProteinMeta =
      const VerificationMeta('targetProtein');
  @override
  late final GeneratedColumn<int> targetProtein = GeneratedColumn<int>(
      'target_protein', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(180));
  static const VerificationMeta _targetCarbsMeta =
      const VerificationMeta('targetCarbs');
  @override
  late final GeneratedColumn<int> targetCarbs = GeneratedColumn<int>(
      'target_carbs', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(250));
  static const VerificationMeta _targetFatMeta =
      const VerificationMeta('targetFat');
  @override
  late final GeneratedColumn<int> targetFat = GeneratedColumn<int>(
      'target_fat', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(80));
  static const VerificationMeta _targetWaterMeta =
      const VerificationMeta('targetWater');
  @override
  late final GeneratedColumn<int> targetWater = GeneratedColumn<int>(
      'target_water', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(3000));
  static const VerificationMeta _targetStepsMeta =
      const VerificationMeta('targetSteps');
  @override
  late final GeneratedColumn<int> targetSteps = GeneratedColumn<int>(
      'target_steps', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(8000));
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        id,
        createdAt,
        updatedAt,
        deletedAt,
        userId,
        themeMode,
        unitSystem,
        targetCalories,
        targetProtein,
        targetCarbs,
        targetFat,
        targetWater,
        targetSteps
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(Insertable<AppSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('theme_mode')) {
      context.handle(_themeModeMeta,
          themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta));
    }
    if (data.containsKey('unit_system')) {
      context.handle(
          _unitSystemMeta,
          unitSystem.isAcceptableOrUnknown(
              data['unit_system']!, _unitSystemMeta));
    }
    if (data.containsKey('target_calories')) {
      context.handle(
          _targetCaloriesMeta,
          targetCalories.isAcceptableOrUnknown(
              data['target_calories']!, _targetCaloriesMeta));
    }
    if (data.containsKey('target_protein')) {
      context.handle(
          _targetProteinMeta,
          targetProtein.isAcceptableOrUnknown(
              data['target_protein']!, _targetProteinMeta));
    }
    if (data.containsKey('target_carbs')) {
      context.handle(
          _targetCarbsMeta,
          targetCarbs.isAcceptableOrUnknown(
              data['target_carbs']!, _targetCarbsMeta));
    }
    if (data.containsKey('target_fat')) {
      context.handle(_targetFatMeta,
          targetFat.isAcceptableOrUnknown(data['target_fat']!, _targetFatMeta));
    }
    if (data.containsKey('target_water')) {
      context.handle(
          _targetWaterMeta,
          targetWater.isAcceptableOrUnknown(
              data['target_water']!, _targetWaterMeta));
    }
    if (data.containsKey('target_steps')) {
      context.handle(
          _targetStepsMeta,
          targetSteps.isAcceptableOrUnknown(
              data['target_steps']!, _targetStepsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}local_id'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      themeMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}theme_mode'])!,
      unitSystem: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit_system'])!,
      targetCalories: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_calories'])!,
      targetProtein: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_protein'])!,
      targetCarbs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_carbs'])!,
      targetFat: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_fat'])!,
      targetWater: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_water'])!,
      targetSteps: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_steps'])!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final int localId;
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String userId;
  final String themeMode;
  final String unitSystem;
  final int targetCalories;
  final int targetProtein;
  final int targetCarbs;
  final int targetFat;
  final int targetWater;
  final int targetSteps;
  const AppSetting(
      {required this.localId,
      required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.userId,
      required this.themeMode,
      required this.unitSystem,
      required this.targetCalories,
      required this.targetProtein,
      required this.targetCarbs,
      required this.targetFat,
      required this.targetWater,
      required this.targetSteps});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['user_id'] = Variable<String>(userId);
    map['theme_mode'] = Variable<String>(themeMode);
    map['unit_system'] = Variable<String>(unitSystem);
    map['target_calories'] = Variable<int>(targetCalories);
    map['target_protein'] = Variable<int>(targetProtein);
    map['target_carbs'] = Variable<int>(targetCarbs);
    map['target_fat'] = Variable<int>(targetFat);
    map['target_water'] = Variable<int>(targetWater);
    map['target_steps'] = Variable<int>(targetSteps);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      localId: Value(localId),
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      userId: Value(userId),
      themeMode: Value(themeMode),
      unitSystem: Value(unitSystem),
      targetCalories: Value(targetCalories),
      targetProtein: Value(targetProtein),
      targetCarbs: Value(targetCarbs),
      targetFat: Value(targetFat),
      targetWater: Value(targetWater),
      targetSteps: Value(targetSteps),
    );
  }

  factory AppSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      localId: serializer.fromJson<int>(json['localId']),
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      userId: serializer.fromJson<String>(json['userId']),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      unitSystem: serializer.fromJson<String>(json['unitSystem']),
      targetCalories: serializer.fromJson<int>(json['targetCalories']),
      targetProtein: serializer.fromJson<int>(json['targetProtein']),
      targetCarbs: serializer.fromJson<int>(json['targetCarbs']),
      targetFat: serializer.fromJson<int>(json['targetFat']),
      targetWater: serializer.fromJson<int>(json['targetWater']),
      targetSteps: serializer.fromJson<int>(json['targetSteps']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'userId': serializer.toJson<String>(userId),
      'themeMode': serializer.toJson<String>(themeMode),
      'unitSystem': serializer.toJson<String>(unitSystem),
      'targetCalories': serializer.toJson<int>(targetCalories),
      'targetProtein': serializer.toJson<int>(targetProtein),
      'targetCarbs': serializer.toJson<int>(targetCarbs),
      'targetFat': serializer.toJson<int>(targetFat),
      'targetWater': serializer.toJson<int>(targetWater),
      'targetSteps': serializer.toJson<int>(targetSteps),
    };
  }

  AppSetting copyWith(
          {int? localId,
          String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? userId,
          String? themeMode,
          String? unitSystem,
          int? targetCalories,
          int? targetProtein,
          int? targetCarbs,
          int? targetFat,
          int? targetWater,
          int? targetSteps}) =>
      AppSetting(
        localId: localId ?? this.localId,
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        userId: userId ?? this.userId,
        themeMode: themeMode ?? this.themeMode,
        unitSystem: unitSystem ?? this.unitSystem,
        targetCalories: targetCalories ?? this.targetCalories,
        targetProtein: targetProtein ?? this.targetProtein,
        targetCarbs: targetCarbs ?? this.targetCarbs,
        targetFat: targetFat ?? this.targetFat,
        targetWater: targetWater ?? this.targetWater,
        targetSteps: targetSteps ?? this.targetSteps,
      );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      localId: data.localId.present ? data.localId.value : this.localId,
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      userId: data.userId.present ? data.userId.value : this.userId,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      unitSystem:
          data.unitSystem.present ? data.unitSystem.value : this.unitSystem,
      targetCalories: data.targetCalories.present
          ? data.targetCalories.value
          : this.targetCalories,
      targetProtein: data.targetProtein.present
          ? data.targetProtein.value
          : this.targetProtein,
      targetCarbs:
          data.targetCarbs.present ? data.targetCarbs.value : this.targetCarbs,
      targetFat: data.targetFat.present ? data.targetFat.value : this.targetFat,
      targetWater:
          data.targetWater.present ? data.targetWater.value : this.targetWater,
      targetSteps:
          data.targetSteps.present ? data.targetSteps.value : this.targetSteps,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('userId: $userId, ')
          ..write('themeMode: $themeMode, ')
          ..write('unitSystem: $unitSystem, ')
          ..write('targetCalories: $targetCalories, ')
          ..write('targetProtein: $targetProtein, ')
          ..write('targetCarbs: $targetCarbs, ')
          ..write('targetFat: $targetFat, ')
          ..write('targetWater: $targetWater, ')
          ..write('targetSteps: $targetSteps')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      localId,
      id,
      createdAt,
      updatedAt,
      deletedAt,
      userId,
      themeMode,
      unitSystem,
      targetCalories,
      targetProtein,
      targetCarbs,
      targetFat,
      targetWater,
      targetSteps);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.localId == this.localId &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.userId == this.userId &&
          other.themeMode == this.themeMode &&
          other.unitSystem == this.unitSystem &&
          other.targetCalories == this.targetCalories &&
          other.targetProtein == this.targetProtein &&
          other.targetCarbs == this.targetCarbs &&
          other.targetFat == this.targetFat &&
          other.targetWater == this.targetWater &&
          other.targetSteps == this.targetSteps);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> localId;
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> userId;
  final Value<String> themeMode;
  final Value<String> unitSystem;
  final Value<int> targetCalories;
  final Value<int> targetProtein;
  final Value<int> targetCarbs;
  final Value<int> targetFat;
  final Value<int> targetWater;
  final Value<int> targetSteps;
  const AppSettingsCompanion({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.userId = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.unitSystem = const Value.absent(),
    this.targetCalories = const Value.absent(),
    this.targetProtein = const Value.absent(),
    this.targetCarbs = const Value.absent(),
    this.targetFat = const Value.absent(),
    this.targetWater = const Value.absent(),
    this.targetSteps = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String userId,
    this.themeMode = const Value.absent(),
    this.unitSystem = const Value.absent(),
    this.targetCalories = const Value.absent(),
    this.targetProtein = const Value.absent(),
    this.targetCarbs = const Value.absent(),
    this.targetFat = const Value.absent(),
    this.targetWater = const Value.absent(),
    this.targetSteps = const Value.absent(),
  }) : userId = Value(userId);
  static Insertable<AppSetting> custom({
    Expression<int>? localId,
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? userId,
    Expression<String>? themeMode,
    Expression<String>? unitSystem,
    Expression<int>? targetCalories,
    Expression<int>? targetProtein,
    Expression<int>? targetCarbs,
    Expression<int>? targetFat,
    Expression<int>? targetWater,
    Expression<int>? targetSteps,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (userId != null) 'user_id': userId,
      if (themeMode != null) 'theme_mode': themeMode,
      if (unitSystem != null) 'unit_system': unitSystem,
      if (targetCalories != null) 'target_calories': targetCalories,
      if (targetProtein != null) 'target_protein': targetProtein,
      if (targetCarbs != null) 'target_carbs': targetCarbs,
      if (targetFat != null) 'target_fat': targetFat,
      if (targetWater != null) 'target_water': targetWater,
      if (targetSteps != null) 'target_steps': targetSteps,
    });
  }

  AppSettingsCompanion copyWith(
      {Value<int>? localId,
      Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? userId,
      Value<String>? themeMode,
      Value<String>? unitSystem,
      Value<int>? targetCalories,
      Value<int>? targetProtein,
      Value<int>? targetCarbs,
      Value<int>? targetFat,
      Value<int>? targetWater,
      Value<int>? targetSteps}) {
    return AppSettingsCompanion(
      localId: localId ?? this.localId,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      userId: userId ?? this.userId,
      themeMode: themeMode ?? this.themeMode,
      unitSystem: unitSystem ?? this.unitSystem,
      targetCalories: targetCalories ?? this.targetCalories,
      targetProtein: targetProtein ?? this.targetProtein,
      targetCarbs: targetCarbs ?? this.targetCarbs,
      targetFat: targetFat ?? this.targetFat,
      targetWater: targetWater ?? this.targetWater,
      targetSteps: targetSteps ?? this.targetSteps,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (unitSystem.present) {
      map['unit_system'] = Variable<String>(unitSystem.value);
    }
    if (targetCalories.present) {
      map['target_calories'] = Variable<int>(targetCalories.value);
    }
    if (targetProtein.present) {
      map['target_protein'] = Variable<int>(targetProtein.value);
    }
    if (targetCarbs.present) {
      map['target_carbs'] = Variable<int>(targetCarbs.value);
    }
    if (targetFat.present) {
      map['target_fat'] = Variable<int>(targetFat.value);
    }
    if (targetWater.present) {
      map['target_water'] = Variable<int>(targetWater.value);
    }
    if (targetSteps.present) {
      map['target_steps'] = Variable<int>(targetSteps.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('userId: $userId, ')
          ..write('themeMode: $themeMode, ')
          ..write('unitSystem: $unitSystem, ')
          ..write('targetCalories: $targetCalories, ')
          ..write('targetProtein: $targetProtein, ')
          ..write('targetCarbs: $targetCarbs, ')
          ..write('targetFat: $targetFat, ')
          ..write('targetWater: $targetWater, ')
          ..write('targetSteps: $targetSteps')
          ..write(')'))
        .toString();
  }
}

class $ExercisesTable extends Exercises
    with TableInfo<$ExercisesTable, Exercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
      'local_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdByMeta =
      const VerificationMeta('createdBy');
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
      'created_by', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameDeMeta = const VerificationMeta('nameDe');
  @override
  late final GeneratedColumn<String> nameDe = GeneratedColumn<String>(
      'name_de', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
      'name_en', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionDeMeta =
      const VerificationMeta('descriptionDe');
  @override
  late final GeneratedColumn<String> descriptionDe = GeneratedColumn<String>(
      'description_de', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _descriptionEnMeta =
      const VerificationMeta('descriptionEn');
  @override
  late final GeneratedColumn<String> descriptionEn = GeneratedColumn<String>(
      'description_en', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryNameMeta =
      const VerificationMeta('categoryName');
  @override
  late final GeneratedColumn<String> categoryName = GeneratedColumn<String>(
      'category_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _imagePathMeta =
      const VerificationMeta('imagePath');
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
      'image_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _musclesPrimaryMeta =
      const VerificationMeta('musclesPrimary');
  @override
  late final GeneratedColumn<String> musclesPrimary = GeneratedColumn<String>(
      'muscles_primary', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _musclesSecondaryMeta =
      const VerificationMeta('musclesSecondary');
  @override
  late final GeneratedColumn<String> musclesSecondary = GeneratedColumn<String>(
      'muscles_secondary', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isCustomMeta =
      const VerificationMeta('isCustom');
  @override
  late final GeneratedColumn<bool> isCustom = GeneratedColumn<bool>(
      'is_custom', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_custom" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('user'));
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        id,
        createdAt,
        updatedAt,
        deletedAt,
        createdBy,
        nameDe,
        nameEn,
        descriptionDe,
        descriptionEn,
        categoryName,
        imagePath,
        musclesPrimary,
        musclesSecondary,
        isCustom,
        source
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercises';
  @override
  VerificationContext validateIntegrity(Insertable<Exercise> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('created_by')) {
      context.handle(_createdByMeta,
          createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta));
    }
    if (data.containsKey('name_de')) {
      context.handle(_nameDeMeta,
          nameDe.isAcceptableOrUnknown(data['name_de']!, _nameDeMeta));
    } else if (isInserting) {
      context.missing(_nameDeMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(_nameEnMeta,
          nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta));
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('description_de')) {
      context.handle(
          _descriptionDeMeta,
          descriptionDe.isAcceptableOrUnknown(
              data['description_de']!, _descriptionDeMeta));
    }
    if (data.containsKey('description_en')) {
      context.handle(
          _descriptionEnMeta,
          descriptionEn.isAcceptableOrUnknown(
              data['description_en']!, _descriptionEnMeta));
    }
    if (data.containsKey('category_name')) {
      context.handle(
          _categoryNameMeta,
          categoryName.isAcceptableOrUnknown(
              data['category_name']!, _categoryNameMeta));
    }
    if (data.containsKey('image_path')) {
      context.handle(_imagePathMeta,
          imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta));
    }
    if (data.containsKey('muscles_primary')) {
      context.handle(
          _musclesPrimaryMeta,
          musclesPrimary.isAcceptableOrUnknown(
              data['muscles_primary']!, _musclesPrimaryMeta));
    }
    if (data.containsKey('muscles_secondary')) {
      context.handle(
          _musclesSecondaryMeta,
          musclesSecondary.isAcceptableOrUnknown(
              data['muscles_secondary']!, _musclesSecondaryMeta));
    }
    if (data.containsKey('is_custom')) {
      context.handle(_isCustomMeta,
          isCustom.isAcceptableOrUnknown(data['is_custom']!, _isCustomMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  Exercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Exercise(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}local_id'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      createdBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_by']),
      nameDe: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_de'])!,
      nameEn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_en'])!,
      descriptionDe: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description_de']),
      descriptionEn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description_en']),
      categoryName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_name']),
      imagePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_path']),
      musclesPrimary: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}muscles_primary']),
      musclesSecondary: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}muscles_secondary']),
      isCustom: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_custom'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
    );
  }

  @override
  $ExercisesTable createAlias(String alias) {
    return $ExercisesTable(attachedDatabase, alias);
  }
}

class Exercise extends DataClass implements Insertable<Exercise> {
  final int localId;
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? createdBy;
  final String nameDe;
  final String nameEn;
  final String? descriptionDe;
  final String? descriptionEn;
  final String? categoryName;
  final String? imagePath;
  final String? musclesPrimary;
  final String? musclesSecondary;
  final bool isCustom;
  final String source;
  const Exercise(
      {required this.localId,
      required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      this.createdBy,
      required this.nameDe,
      required this.nameEn,
      this.descriptionDe,
      this.descriptionEn,
      this.categoryName,
      this.imagePath,
      this.musclesPrimary,
      this.musclesSecondary,
      required this.isCustom,
      required this.source});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    map['name_de'] = Variable<String>(nameDe);
    map['name_en'] = Variable<String>(nameEn);
    if (!nullToAbsent || descriptionDe != null) {
      map['description_de'] = Variable<String>(descriptionDe);
    }
    if (!nullToAbsent || descriptionEn != null) {
      map['description_en'] = Variable<String>(descriptionEn);
    }
    if (!nullToAbsent || categoryName != null) {
      map['category_name'] = Variable<String>(categoryName);
    }
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    if (!nullToAbsent || musclesPrimary != null) {
      map['muscles_primary'] = Variable<String>(musclesPrimary);
    }
    if (!nullToAbsent || musclesSecondary != null) {
      map['muscles_secondary'] = Variable<String>(musclesSecondary);
    }
    map['is_custom'] = Variable<bool>(isCustom);
    map['source'] = Variable<String>(source);
    return map;
  }

  ExercisesCompanion toCompanion(bool nullToAbsent) {
    return ExercisesCompanion(
      localId: Value(localId),
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      nameDe: Value(nameDe),
      nameEn: Value(nameEn),
      descriptionDe: descriptionDe == null && nullToAbsent
          ? const Value.absent()
          : Value(descriptionDe),
      descriptionEn: descriptionEn == null && nullToAbsent
          ? const Value.absent()
          : Value(descriptionEn),
      categoryName: categoryName == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryName),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      musclesPrimary: musclesPrimary == null && nullToAbsent
          ? const Value.absent()
          : Value(musclesPrimary),
      musclesSecondary: musclesSecondary == null && nullToAbsent
          ? const Value.absent()
          : Value(musclesSecondary),
      isCustom: Value(isCustom),
      source: Value(source),
    );
  }

  factory Exercise.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Exercise(
      localId: serializer.fromJson<int>(json['localId']),
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      nameDe: serializer.fromJson<String>(json['nameDe']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      descriptionDe: serializer.fromJson<String?>(json['descriptionDe']),
      descriptionEn: serializer.fromJson<String?>(json['descriptionEn']),
      categoryName: serializer.fromJson<String?>(json['categoryName']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      musclesPrimary: serializer.fromJson<String?>(json['musclesPrimary']),
      musclesSecondary: serializer.fromJson<String?>(json['musclesSecondary']),
      isCustom: serializer.fromJson<bool>(json['isCustom']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'createdBy': serializer.toJson<String?>(createdBy),
      'nameDe': serializer.toJson<String>(nameDe),
      'nameEn': serializer.toJson<String>(nameEn),
      'descriptionDe': serializer.toJson<String?>(descriptionDe),
      'descriptionEn': serializer.toJson<String?>(descriptionEn),
      'categoryName': serializer.toJson<String?>(categoryName),
      'imagePath': serializer.toJson<String?>(imagePath),
      'musclesPrimary': serializer.toJson<String?>(musclesPrimary),
      'musclesSecondary': serializer.toJson<String?>(musclesSecondary),
      'isCustom': serializer.toJson<bool>(isCustom),
      'source': serializer.toJson<String>(source),
    };
  }

  Exercise copyWith(
          {int? localId,
          String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          Value<String?> createdBy = const Value.absent(),
          String? nameDe,
          String? nameEn,
          Value<String?> descriptionDe = const Value.absent(),
          Value<String?> descriptionEn = const Value.absent(),
          Value<String?> categoryName = const Value.absent(),
          Value<String?> imagePath = const Value.absent(),
          Value<String?> musclesPrimary = const Value.absent(),
          Value<String?> musclesSecondary = const Value.absent(),
          bool? isCustom,
          String? source}) =>
      Exercise(
        localId: localId ?? this.localId,
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        createdBy: createdBy.present ? createdBy.value : this.createdBy,
        nameDe: nameDe ?? this.nameDe,
        nameEn: nameEn ?? this.nameEn,
        descriptionDe:
            descriptionDe.present ? descriptionDe.value : this.descriptionDe,
        descriptionEn:
            descriptionEn.present ? descriptionEn.value : this.descriptionEn,
        categoryName:
            categoryName.present ? categoryName.value : this.categoryName,
        imagePath: imagePath.present ? imagePath.value : this.imagePath,
        musclesPrimary:
            musclesPrimary.present ? musclesPrimary.value : this.musclesPrimary,
        musclesSecondary: musclesSecondary.present
            ? musclesSecondary.value
            : this.musclesSecondary,
        isCustom: isCustom ?? this.isCustom,
        source: source ?? this.source,
      );
  Exercise copyWithCompanion(ExercisesCompanion data) {
    return Exercise(
      localId: data.localId.present ? data.localId.value : this.localId,
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      nameDe: data.nameDe.present ? data.nameDe.value : this.nameDe,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      descriptionDe: data.descriptionDe.present
          ? data.descriptionDe.value
          : this.descriptionDe,
      descriptionEn: data.descriptionEn.present
          ? data.descriptionEn.value
          : this.descriptionEn,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      musclesPrimary: data.musclesPrimary.present
          ? data.musclesPrimary.value
          : this.musclesPrimary,
      musclesSecondary: data.musclesSecondary.present
          ? data.musclesSecondary.value
          : this.musclesSecondary,
      isCustom: data.isCustom.present ? data.isCustom.value : this.isCustom,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Exercise(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('nameDe: $nameDe, ')
          ..write('nameEn: $nameEn, ')
          ..write('descriptionDe: $descriptionDe, ')
          ..write('descriptionEn: $descriptionEn, ')
          ..write('categoryName: $categoryName, ')
          ..write('imagePath: $imagePath, ')
          ..write('musclesPrimary: $musclesPrimary, ')
          ..write('musclesSecondary: $musclesSecondary, ')
          ..write('isCustom: $isCustom, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      localId,
      id,
      createdAt,
      updatedAt,
      deletedAt,
      createdBy,
      nameDe,
      nameEn,
      descriptionDe,
      descriptionEn,
      categoryName,
      imagePath,
      musclesPrimary,
      musclesSecondary,
      isCustom,
      source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Exercise &&
          other.localId == this.localId &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdBy == this.createdBy &&
          other.nameDe == this.nameDe &&
          other.nameEn == this.nameEn &&
          other.descriptionDe == this.descriptionDe &&
          other.descriptionEn == this.descriptionEn &&
          other.categoryName == this.categoryName &&
          other.imagePath == this.imagePath &&
          other.musclesPrimary == this.musclesPrimary &&
          other.musclesSecondary == this.musclesSecondary &&
          other.isCustom == this.isCustom &&
          other.source == this.source);
}

class ExercisesCompanion extends UpdateCompanion<Exercise> {
  final Value<int> localId;
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> createdBy;
  final Value<String> nameDe;
  final Value<String> nameEn;
  final Value<String?> descriptionDe;
  final Value<String?> descriptionEn;
  final Value<String?> categoryName;
  final Value<String?> imagePath;
  final Value<String?> musclesPrimary;
  final Value<String?> musclesSecondary;
  final Value<bool> isCustom;
  final Value<String> source;
  const ExercisesCompanion({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.nameDe = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.descriptionDe = const Value.absent(),
    this.descriptionEn = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.musclesPrimary = const Value.absent(),
    this.musclesSecondary = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.source = const Value.absent(),
  });
  ExercisesCompanion.insert({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    required String nameDe,
    required String nameEn,
    this.descriptionDe = const Value.absent(),
    this.descriptionEn = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.musclesPrimary = const Value.absent(),
    this.musclesSecondary = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.source = const Value.absent(),
  })  : nameDe = Value(nameDe),
        nameEn = Value(nameEn);
  static Insertable<Exercise> custom({
    Expression<int>? localId,
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? createdBy,
    Expression<String>? nameDe,
    Expression<String>? nameEn,
    Expression<String>? descriptionDe,
    Expression<String>? descriptionEn,
    Expression<String>? categoryName,
    Expression<String>? imagePath,
    Expression<String>? musclesPrimary,
    Expression<String>? musclesSecondary,
    Expression<bool>? isCustom,
    Expression<String>? source,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdBy != null) 'created_by': createdBy,
      if (nameDe != null) 'name_de': nameDe,
      if (nameEn != null) 'name_en': nameEn,
      if (descriptionDe != null) 'description_de': descriptionDe,
      if (descriptionEn != null) 'description_en': descriptionEn,
      if (categoryName != null) 'category_name': categoryName,
      if (imagePath != null) 'image_path': imagePath,
      if (musclesPrimary != null) 'muscles_primary': musclesPrimary,
      if (musclesSecondary != null) 'muscles_secondary': musclesSecondary,
      if (isCustom != null) 'is_custom': isCustom,
      if (source != null) 'source': source,
    });
  }

  ExercisesCompanion copyWith(
      {Value<int>? localId,
      Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String?>? createdBy,
      Value<String>? nameDe,
      Value<String>? nameEn,
      Value<String?>? descriptionDe,
      Value<String?>? descriptionEn,
      Value<String?>? categoryName,
      Value<String?>? imagePath,
      Value<String?>? musclesPrimary,
      Value<String?>? musclesSecondary,
      Value<bool>? isCustom,
      Value<String>? source}) {
    return ExercisesCompanion(
      localId: localId ?? this.localId,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdBy: createdBy ?? this.createdBy,
      nameDe: nameDe ?? this.nameDe,
      nameEn: nameEn ?? this.nameEn,
      descriptionDe: descriptionDe ?? this.descriptionDe,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      categoryName: categoryName ?? this.categoryName,
      imagePath: imagePath ?? this.imagePath,
      musclesPrimary: musclesPrimary ?? this.musclesPrimary,
      musclesSecondary: musclesSecondary ?? this.musclesSecondary,
      isCustom: isCustom ?? this.isCustom,
      source: source ?? this.source,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (nameDe.present) {
      map['name_de'] = Variable<String>(nameDe.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (descriptionDe.present) {
      map['description_de'] = Variable<String>(descriptionDe.value);
    }
    if (descriptionEn.present) {
      map['description_en'] = Variable<String>(descriptionEn.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (musclesPrimary.present) {
      map['muscles_primary'] = Variable<String>(musclesPrimary.value);
    }
    if (musclesSecondary.present) {
      map['muscles_secondary'] = Variable<String>(musclesSecondary.value);
    }
    if (isCustom.present) {
      map['is_custom'] = Variable<bool>(isCustom.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExercisesCompanion(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('nameDe: $nameDe, ')
          ..write('nameEn: $nameEn, ')
          ..write('descriptionDe: $descriptionDe, ')
          ..write('descriptionEn: $descriptionEn, ')
          ..write('categoryName: $categoryName, ')
          ..write('imagePath: $imagePath, ')
          ..write('musclesPrimary: $musclesPrimary, ')
          ..write('musclesSecondary: $musclesSecondary, ')
          ..write('isCustom: $isCustom, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }
}

class $RoutinesTable extends Routines with TableInfo<$RoutinesTable, Routine> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoutinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
      'local_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isPublicMeta =
      const VerificationMeta('isPublic');
  @override
  late final GeneratedColumn<bool> isPublic = GeneratedColumn<bool>(
      'is_public', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_public" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [localId, id, createdAt, updatedAt, deletedAt, userId, name, isPublic];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'routines';
  @override
  VerificationContext validateIntegrity(Insertable<Routine> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_public')) {
      context.handle(_isPublicMeta,
          isPublic.isAcceptableOrUnknown(data['is_public']!, _isPublicMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  Routine map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Routine(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}local_id'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      isPublic: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_public'])!,
    );
  }

  @override
  $RoutinesTable createAlias(String alias) {
    return $RoutinesTable(attachedDatabase, alias);
  }
}

class Routine extends DataClass implements Insertable<Routine> {
  final int localId;
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? userId;
  final String name;
  final bool isPublic;
  const Routine(
      {required this.localId,
      required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      this.userId,
      required this.name,
      required this.isPublic});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['name'] = Variable<String>(name);
    map['is_public'] = Variable<bool>(isPublic);
    return map;
  }

  RoutinesCompanion toCompanion(bool nullToAbsent) {
    return RoutinesCompanion(
      localId: Value(localId),
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      name: Value(name),
      isPublic: Value(isPublic),
    );
  }

  factory Routine.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Routine(
      localId: serializer.fromJson<int>(json['localId']),
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      userId: serializer.fromJson<String?>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      isPublic: serializer.fromJson<bool>(json['isPublic']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'userId': serializer.toJson<String?>(userId),
      'name': serializer.toJson<String>(name),
      'isPublic': serializer.toJson<bool>(isPublic),
    };
  }

  Routine copyWith(
          {int? localId,
          String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          Value<String?> userId = const Value.absent(),
          String? name,
          bool? isPublic}) =>
      Routine(
        localId: localId ?? this.localId,
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        userId: userId.present ? userId.value : this.userId,
        name: name ?? this.name,
        isPublic: isPublic ?? this.isPublic,
      );
  Routine copyWithCompanion(RoutinesCompanion data) {
    return Routine(
      localId: data.localId.present ? data.localId.value : this.localId,
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      isPublic: data.isPublic.present ? data.isPublic.value : this.isPublic,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Routine(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('isPublic: $isPublic')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      localId, id, createdAt, updatedAt, deletedAt, userId, name, isPublic);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Routine &&
          other.localId == this.localId &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.isPublic == this.isPublic);
}

class RoutinesCompanion extends UpdateCompanion<Routine> {
  final Value<int> localId;
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> userId;
  final Value<String> name;
  final Value<bool> isPublic;
  const RoutinesCompanion({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.isPublic = const Value.absent(),
  });
  RoutinesCompanion.insert({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.userId = const Value.absent(),
    required String name,
    this.isPublic = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Routine> custom({
    Expression<int>? localId,
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<bool>? isPublic,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (isPublic != null) 'is_public': isPublic,
    });
  }

  RoutinesCompanion copyWith(
      {Value<int>? localId,
      Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String?>? userId,
      Value<String>? name,
      Value<bool>? isPublic}) {
    return RoutinesCompanion(
      localId: localId ?? this.localId,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isPublic.present) {
      map['is_public'] = Variable<bool>(isPublic.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoutinesCompanion(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('isPublic: $isPublic')
          ..write(')'))
        .toString();
  }
}

class $RoutineExercisesTable extends RoutineExercises
    with TableInfo<$RoutineExercisesTable, RoutineExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoutineExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
      'local_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _routineIdMeta =
      const VerificationMeta('routineId');
  @override
  late final GeneratedColumn<String> routineId = GeneratedColumn<String>(
      'routine_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES routines (id) ON DELETE CASCADE'));
  static const VerificationMeta _exerciseIdMeta =
      const VerificationMeta('exerciseId');
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
      'exercise_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES exercises (id)'));
  static const VerificationMeta _orderIndexMeta =
      const VerificationMeta('orderIndex');
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
      'order_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _pauseSecondsMeta =
      const VerificationMeta('pauseSeconds');
  @override
  late final GeneratedColumn<int> pauseSeconds = GeneratedColumn<int>(
      'pause_seconds', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        id,
        createdAt,
        updatedAt,
        deletedAt,
        routineId,
        exerciseId,
        orderIndex,
        pauseSeconds
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'routine_exercises';
  @override
  VerificationContext validateIntegrity(Insertable<RoutineExercise> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('routine_id')) {
      context.handle(_routineIdMeta,
          routineId.isAcceptableOrUnknown(data['routine_id']!, _routineIdMeta));
    } else if (isInserting) {
      context.missing(_routineIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
          _exerciseIdMeta,
          exerciseId.isAcceptableOrUnknown(
              data['exercise_id']!, _exerciseIdMeta));
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
          _orderIndexMeta,
          orderIndex.isAcceptableOrUnknown(
              data['order_index']!, _orderIndexMeta));
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('pause_seconds')) {
      context.handle(
          _pauseSecondsMeta,
          pauseSeconds.isAcceptableOrUnknown(
              data['pause_seconds']!, _pauseSecondsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  RoutineExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoutineExercise(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}local_id'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      routineId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}routine_id'])!,
      exerciseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exercise_id'])!,
      orderIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order_index'])!,
      pauseSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}pause_seconds']),
    );
  }

  @override
  $RoutineExercisesTable createAlias(String alias) {
    return $RoutineExercisesTable(attachedDatabase, alias);
  }
}

class RoutineExercise extends DataClass implements Insertable<RoutineExercise> {
  final int localId;
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String routineId;
  final String exerciseId;
  final int orderIndex;
  final int? pauseSeconds;
  const RoutineExercise(
      {required this.localId,
      required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.routineId,
      required this.exerciseId,
      required this.orderIndex,
      this.pauseSeconds});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['routine_id'] = Variable<String>(routineId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['order_index'] = Variable<int>(orderIndex);
    if (!nullToAbsent || pauseSeconds != null) {
      map['pause_seconds'] = Variable<int>(pauseSeconds);
    }
    return map;
  }

  RoutineExercisesCompanion toCompanion(bool nullToAbsent) {
    return RoutineExercisesCompanion(
      localId: Value(localId),
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      routineId: Value(routineId),
      exerciseId: Value(exerciseId),
      orderIndex: Value(orderIndex),
      pauseSeconds: pauseSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(pauseSeconds),
    );
  }

  factory RoutineExercise.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoutineExercise(
      localId: serializer.fromJson<int>(json['localId']),
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      routineId: serializer.fromJson<String>(json['routineId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      pauseSeconds: serializer.fromJson<int?>(json['pauseSeconds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'routineId': serializer.toJson<String>(routineId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'pauseSeconds': serializer.toJson<int?>(pauseSeconds),
    };
  }

  RoutineExercise copyWith(
          {int? localId,
          String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? routineId,
          String? exerciseId,
          int? orderIndex,
          Value<int?> pauseSeconds = const Value.absent()}) =>
      RoutineExercise(
        localId: localId ?? this.localId,
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        routineId: routineId ?? this.routineId,
        exerciseId: exerciseId ?? this.exerciseId,
        orderIndex: orderIndex ?? this.orderIndex,
        pauseSeconds:
            pauseSeconds.present ? pauseSeconds.value : this.pauseSeconds,
      );
  RoutineExercise copyWithCompanion(RoutineExercisesCompanion data) {
    return RoutineExercise(
      localId: data.localId.present ? data.localId.value : this.localId,
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      routineId: data.routineId.present ? data.routineId.value : this.routineId,
      exerciseId:
          data.exerciseId.present ? data.exerciseId.value : this.exerciseId,
      orderIndex:
          data.orderIndex.present ? data.orderIndex.value : this.orderIndex,
      pauseSeconds: data.pauseSeconds.present
          ? data.pauseSeconds.value
          : this.pauseSeconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoutineExercise(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('routineId: $routineId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('pauseSeconds: $pauseSeconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(localId, id, createdAt, updatedAt, deletedAt,
      routineId, exerciseId, orderIndex, pauseSeconds);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoutineExercise &&
          other.localId == this.localId &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.routineId == this.routineId &&
          other.exerciseId == this.exerciseId &&
          other.orderIndex == this.orderIndex &&
          other.pauseSeconds == this.pauseSeconds);
}

class RoutineExercisesCompanion extends UpdateCompanion<RoutineExercise> {
  final Value<int> localId;
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> routineId;
  final Value<String> exerciseId;
  final Value<int> orderIndex;
  final Value<int?> pauseSeconds;
  const RoutineExercisesCompanion({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.routineId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.pauseSeconds = const Value.absent(),
  });
  RoutineExercisesCompanion.insert({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String routineId,
    required String exerciseId,
    required int orderIndex,
    this.pauseSeconds = const Value.absent(),
  })  : routineId = Value(routineId),
        exerciseId = Value(exerciseId),
        orderIndex = Value(orderIndex);
  static Insertable<RoutineExercise> custom({
    Expression<int>? localId,
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? routineId,
    Expression<String>? exerciseId,
    Expression<int>? orderIndex,
    Expression<int>? pauseSeconds,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (routineId != null) 'routine_id': routineId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (orderIndex != null) 'order_index': orderIndex,
      if (pauseSeconds != null) 'pause_seconds': pauseSeconds,
    });
  }

  RoutineExercisesCompanion copyWith(
      {Value<int>? localId,
      Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? routineId,
      Value<String>? exerciseId,
      Value<int>? orderIndex,
      Value<int?>? pauseSeconds}) {
    return RoutineExercisesCompanion(
      localId: localId ?? this.localId,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      routineId: routineId ?? this.routineId,
      exerciseId: exerciseId ?? this.exerciseId,
      orderIndex: orderIndex ?? this.orderIndex,
      pauseSeconds: pauseSeconds ?? this.pauseSeconds,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (routineId.present) {
      map['routine_id'] = Variable<String>(routineId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (pauseSeconds.present) {
      map['pause_seconds'] = Variable<int>(pauseSeconds.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoutineExercisesCompanion(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('routineId: $routineId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('pauseSeconds: $pauseSeconds')
          ..write(')'))
        .toString();
  }
}

class $RoutineSetTemplatesTable extends RoutineSetTemplates
    with TableInfo<$RoutineSetTemplatesTable, RoutineSetTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoutineSetTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
      'local_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _routineExerciseIdMeta =
      const VerificationMeta('routineExerciseId');
  @override
  late final GeneratedColumn<String> routineExerciseId =
      GeneratedColumn<String>('routine_exercise_id', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: true,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'REFERENCES routine_exercises (id) ON DELETE CASCADE'));
  static const VerificationMeta _setTypeMeta =
      const VerificationMeta('setType');
  @override
  late final GeneratedColumn<String> setType = GeneratedColumn<String>(
      'set_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('normal'));
  static const VerificationMeta _targetRepsMeta =
      const VerificationMeta('targetReps');
  @override
  late final GeneratedColumn<String> targetReps = GeneratedColumn<String>(
      'target_reps', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _targetWeightMeta =
      const VerificationMeta('targetWeight');
  @override
  late final GeneratedColumn<double> targetWeight = GeneratedColumn<double>(
      'target_weight', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _targetRirMeta =
      const VerificationMeta('targetRir');
  @override
  late final GeneratedColumn<int> targetRir = GeneratedColumn<int>(
      'target_rir', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        id,
        createdAt,
        updatedAt,
        deletedAt,
        routineExerciseId,
        setType,
        targetReps,
        targetWeight,
        targetRir
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'routine_set_templates';
  @override
  VerificationContext validateIntegrity(Insertable<RoutineSetTemplate> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('routine_exercise_id')) {
      context.handle(
          _routineExerciseIdMeta,
          routineExerciseId.isAcceptableOrUnknown(
              data['routine_exercise_id']!, _routineExerciseIdMeta));
    } else if (isInserting) {
      context.missing(_routineExerciseIdMeta);
    }
    if (data.containsKey('set_type')) {
      context.handle(_setTypeMeta,
          setType.isAcceptableOrUnknown(data['set_type']!, _setTypeMeta));
    }
    if (data.containsKey('target_reps')) {
      context.handle(
          _targetRepsMeta,
          targetReps.isAcceptableOrUnknown(
              data['target_reps']!, _targetRepsMeta));
    }
    if (data.containsKey('target_weight')) {
      context.handle(
          _targetWeightMeta,
          targetWeight.isAcceptableOrUnknown(
              data['target_weight']!, _targetWeightMeta));
    }
    if (data.containsKey('target_rir')) {
      context.handle(_targetRirMeta,
          targetRir.isAcceptableOrUnknown(data['target_rir']!, _targetRirMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  RoutineSetTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoutineSetTemplate(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}local_id'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      routineExerciseId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}routine_exercise_id'])!,
      setType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}set_type'])!,
      targetReps: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_reps']),
      targetWeight: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}target_weight']),
      targetRir: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_rir']),
    );
  }

  @override
  $RoutineSetTemplatesTable createAlias(String alias) {
    return $RoutineSetTemplatesTable(attachedDatabase, alias);
  }
}

class RoutineSetTemplate extends DataClass
    implements Insertable<RoutineSetTemplate> {
  final int localId;
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String routineExerciseId;
  final String setType;
  final String? targetReps;
  final double? targetWeight;
  final int? targetRir;
  const RoutineSetTemplate(
      {required this.localId,
      required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.routineExerciseId,
      required this.setType,
      this.targetReps,
      this.targetWeight,
      this.targetRir});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['routine_exercise_id'] = Variable<String>(routineExerciseId);
    map['set_type'] = Variable<String>(setType);
    if (!nullToAbsent || targetReps != null) {
      map['target_reps'] = Variable<String>(targetReps);
    }
    if (!nullToAbsent || targetWeight != null) {
      map['target_weight'] = Variable<double>(targetWeight);
    }
    if (!nullToAbsent || targetRir != null) {
      map['target_rir'] = Variable<int>(targetRir);
    }
    return map;
  }

  RoutineSetTemplatesCompanion toCompanion(bool nullToAbsent) {
    return RoutineSetTemplatesCompanion(
      localId: Value(localId),
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      routineExerciseId: Value(routineExerciseId),
      setType: Value(setType),
      targetReps: targetReps == null && nullToAbsent
          ? const Value.absent()
          : Value(targetReps),
      targetWeight: targetWeight == null && nullToAbsent
          ? const Value.absent()
          : Value(targetWeight),
      targetRir: targetRir == null && nullToAbsent
          ? const Value.absent()
          : Value(targetRir),
    );
  }

  factory RoutineSetTemplate.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoutineSetTemplate(
      localId: serializer.fromJson<int>(json['localId']),
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      routineExerciseId: serializer.fromJson<String>(json['routineExerciseId']),
      setType: serializer.fromJson<String>(json['setType']),
      targetReps: serializer.fromJson<String?>(json['targetReps']),
      targetWeight: serializer.fromJson<double?>(json['targetWeight']),
      targetRir: serializer.fromJson<int?>(json['targetRir']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'routineExerciseId': serializer.toJson<String>(routineExerciseId),
      'setType': serializer.toJson<String>(setType),
      'targetReps': serializer.toJson<String?>(targetReps),
      'targetWeight': serializer.toJson<double?>(targetWeight),
      'targetRir': serializer.toJson<int?>(targetRir),
    };
  }

  RoutineSetTemplate copyWith(
          {int? localId,
          String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? routineExerciseId,
          String? setType,
          Value<String?> targetReps = const Value.absent(),
          Value<double?> targetWeight = const Value.absent(),
          Value<int?> targetRir = const Value.absent()}) =>
      RoutineSetTemplate(
        localId: localId ?? this.localId,
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        routineExerciseId: routineExerciseId ?? this.routineExerciseId,
        setType: setType ?? this.setType,
        targetReps: targetReps.present ? targetReps.value : this.targetReps,
        targetWeight:
            targetWeight.present ? targetWeight.value : this.targetWeight,
        targetRir: targetRir.present ? targetRir.value : this.targetRir,
      );
  RoutineSetTemplate copyWithCompanion(RoutineSetTemplatesCompanion data) {
    return RoutineSetTemplate(
      localId: data.localId.present ? data.localId.value : this.localId,
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      routineExerciseId: data.routineExerciseId.present
          ? data.routineExerciseId.value
          : this.routineExerciseId,
      setType: data.setType.present ? data.setType.value : this.setType,
      targetReps:
          data.targetReps.present ? data.targetReps.value : this.targetReps,
      targetWeight: data.targetWeight.present
          ? data.targetWeight.value
          : this.targetWeight,
      targetRir: data.targetRir.present ? data.targetRir.value : this.targetRir,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoutineSetTemplate(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('routineExerciseId: $routineExerciseId, ')
          ..write('setType: $setType, ')
          ..write('targetReps: $targetReps, ')
          ..write('targetWeight: $targetWeight, ')
          ..write('targetRir: $targetRir')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(localId, id, createdAt, updatedAt, deletedAt,
      routineExerciseId, setType, targetReps, targetWeight, targetRir);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoutineSetTemplate &&
          other.localId == this.localId &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.routineExerciseId == this.routineExerciseId &&
          other.setType == this.setType &&
          other.targetReps == this.targetReps &&
          other.targetWeight == this.targetWeight &&
          other.targetRir == this.targetRir);
}

class RoutineSetTemplatesCompanion extends UpdateCompanion<RoutineSetTemplate> {
  final Value<int> localId;
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> routineExerciseId;
  final Value<String> setType;
  final Value<String?> targetReps;
  final Value<double?> targetWeight;
  final Value<int?> targetRir;
  const RoutineSetTemplatesCompanion({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.routineExerciseId = const Value.absent(),
    this.setType = const Value.absent(),
    this.targetReps = const Value.absent(),
    this.targetWeight = const Value.absent(),
    this.targetRir = const Value.absent(),
  });
  RoutineSetTemplatesCompanion.insert({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String routineExerciseId,
    this.setType = const Value.absent(),
    this.targetReps = const Value.absent(),
    this.targetWeight = const Value.absent(),
    this.targetRir = const Value.absent(),
  }) : routineExerciseId = Value(routineExerciseId);
  static Insertable<RoutineSetTemplate> custom({
    Expression<int>? localId,
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? routineExerciseId,
    Expression<String>? setType,
    Expression<String>? targetReps,
    Expression<double>? targetWeight,
    Expression<int>? targetRir,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (routineExerciseId != null) 'routine_exercise_id': routineExerciseId,
      if (setType != null) 'set_type': setType,
      if (targetReps != null) 'target_reps': targetReps,
      if (targetWeight != null) 'target_weight': targetWeight,
      if (targetRir != null) 'target_rir': targetRir,
    });
  }

  RoutineSetTemplatesCompanion copyWith(
      {Value<int>? localId,
      Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? routineExerciseId,
      Value<String>? setType,
      Value<String?>? targetReps,
      Value<double?>? targetWeight,
      Value<int?>? targetRir}) {
    return RoutineSetTemplatesCompanion(
      localId: localId ?? this.localId,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      routineExerciseId: routineExerciseId ?? this.routineExerciseId,
      setType: setType ?? this.setType,
      targetReps: targetReps ?? this.targetReps,
      targetWeight: targetWeight ?? this.targetWeight,
      targetRir: targetRir ?? this.targetRir,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (routineExerciseId.present) {
      map['routine_exercise_id'] = Variable<String>(routineExerciseId.value);
    }
    if (setType.present) {
      map['set_type'] = Variable<String>(setType.value);
    }
    if (targetReps.present) {
      map['target_reps'] = Variable<String>(targetReps.value);
    }
    if (targetWeight.present) {
      map['target_weight'] = Variable<double>(targetWeight.value);
    }
    if (targetRir.present) {
      map['target_rir'] = Variable<int>(targetRir.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoutineSetTemplatesCompanion(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('routineExerciseId: $routineExerciseId, ')
          ..write('setType: $setType, ')
          ..write('targetReps: $targetReps, ')
          ..write('targetWeight: $targetWeight, ')
          ..write('targetRir: $targetRir')
          ..write(')'))
        .toString();
  }
}

class $WorkoutLogsTable extends WorkoutLogs
    with TableInfo<$WorkoutLogsTable, WorkoutLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
      'local_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _routineIdMeta =
      const VerificationMeta('routineId');
  @override
  late final GeneratedColumn<String> routineId = GeneratedColumn<String>(
      'routine_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES routines (id)'));
  static const VerificationMeta _routineNameSnapshotMeta =
      const VerificationMeta('routineNameSnapshot');
  @override
  late final GeneratedColumn<String> routineNameSnapshot =
      GeneratedColumn<String>('routine_name_snapshot', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
      'start_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
      'end_time', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('ongoing'));
  static const VerificationMeta _visibilityMeta =
      const VerificationMeta('visibility');
  @override
  late final GeneratedColumn<String> visibility = GeneratedColumn<String>(
      'visibility', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('private'));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        id,
        createdAt,
        updatedAt,
        deletedAt,
        userId,
        routineId,
        routineNameSnapshot,
        startTime,
        endTime,
        status,
        visibility,
        notes
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_logs';
  @override
  VerificationContext validateIntegrity(Insertable<WorkoutLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('routine_id')) {
      context.handle(_routineIdMeta,
          routineId.isAcceptableOrUnknown(data['routine_id']!, _routineIdMeta));
    }
    if (data.containsKey('routine_name_snapshot')) {
      context.handle(
          _routineNameSnapshotMeta,
          routineNameSnapshot.isAcceptableOrUnknown(
              data['routine_name_snapshot']!, _routineNameSnapshotMeta));
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('visibility')) {
      context.handle(
          _visibilityMeta,
          visibility.isAcceptableOrUnknown(
              data['visibility']!, _visibilityMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  WorkoutLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutLog(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}local_id'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      routineId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}routine_id']),
      routineNameSnapshot: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}routine_name_snapshot']),
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_time'])!,
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_time']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      visibility: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}visibility'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
    );
  }

  @override
  $WorkoutLogsTable createAlias(String alias) {
    return $WorkoutLogsTable(attachedDatabase, alias);
  }
}

class WorkoutLog extends DataClass implements Insertable<WorkoutLog> {
  final int localId;
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? userId;
  final String? routineId;
  final String? routineNameSnapshot;
  final DateTime startTime;
  final DateTime? endTime;
  final String status;
  final String visibility;
  final String? notes;
  const WorkoutLog(
      {required this.localId,
      required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      this.userId,
      this.routineId,
      this.routineNameSnapshot,
      required this.startTime,
      this.endTime,
      required this.status,
      required this.visibility,
      this.notes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || routineId != null) {
      map['routine_id'] = Variable<String>(routineId);
    }
    if (!nullToAbsent || routineNameSnapshot != null) {
      map['routine_name_snapshot'] = Variable<String>(routineNameSnapshot);
    }
    map['start_time'] = Variable<DateTime>(startTime);
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<DateTime>(endTime);
    }
    map['status'] = Variable<String>(status);
    map['visibility'] = Variable<String>(visibility);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  WorkoutLogsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutLogsCompanion(
      localId: Value(localId),
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      routineId: routineId == null && nullToAbsent
          ? const Value.absent()
          : Value(routineId),
      routineNameSnapshot: routineNameSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(routineNameSnapshot),
      startTime: Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      status: Value(status),
      visibility: Value(visibility),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
    );
  }

  factory WorkoutLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutLog(
      localId: serializer.fromJson<int>(json['localId']),
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      userId: serializer.fromJson<String?>(json['userId']),
      routineId: serializer.fromJson<String?>(json['routineId']),
      routineNameSnapshot:
          serializer.fromJson<String?>(json['routineNameSnapshot']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime?>(json['endTime']),
      status: serializer.fromJson<String>(json['status']),
      visibility: serializer.fromJson<String>(json['visibility']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'userId': serializer.toJson<String?>(userId),
      'routineId': serializer.toJson<String?>(routineId),
      'routineNameSnapshot': serializer.toJson<String?>(routineNameSnapshot),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime?>(endTime),
      'status': serializer.toJson<String>(status),
      'visibility': serializer.toJson<String>(visibility),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  WorkoutLog copyWith(
          {int? localId,
          String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          Value<String?> userId = const Value.absent(),
          Value<String?> routineId = const Value.absent(),
          Value<String?> routineNameSnapshot = const Value.absent(),
          DateTime? startTime,
          Value<DateTime?> endTime = const Value.absent(),
          String? status,
          String? visibility,
          Value<String?> notes = const Value.absent()}) =>
      WorkoutLog(
        localId: localId ?? this.localId,
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        userId: userId.present ? userId.value : this.userId,
        routineId: routineId.present ? routineId.value : this.routineId,
        routineNameSnapshot: routineNameSnapshot.present
            ? routineNameSnapshot.value
            : this.routineNameSnapshot,
        startTime: startTime ?? this.startTime,
        endTime: endTime.present ? endTime.value : this.endTime,
        status: status ?? this.status,
        visibility: visibility ?? this.visibility,
        notes: notes.present ? notes.value : this.notes,
      );
  WorkoutLog copyWithCompanion(WorkoutLogsCompanion data) {
    return WorkoutLog(
      localId: data.localId.present ? data.localId.value : this.localId,
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      userId: data.userId.present ? data.userId.value : this.userId,
      routineId: data.routineId.present ? data.routineId.value : this.routineId,
      routineNameSnapshot: data.routineNameSnapshot.present
          ? data.routineNameSnapshot.value
          : this.routineNameSnapshot,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      status: data.status.present ? data.status.value : this.status,
      visibility:
          data.visibility.present ? data.visibility.value : this.visibility,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutLog(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('userId: $userId, ')
          ..write('routineId: $routineId, ')
          ..write('routineNameSnapshot: $routineNameSnapshot, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('status: $status, ')
          ..write('visibility: $visibility, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      localId,
      id,
      createdAt,
      updatedAt,
      deletedAt,
      userId,
      routineId,
      routineNameSnapshot,
      startTime,
      endTime,
      status,
      visibility,
      notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutLog &&
          other.localId == this.localId &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.userId == this.userId &&
          other.routineId == this.routineId &&
          other.routineNameSnapshot == this.routineNameSnapshot &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.status == this.status &&
          other.visibility == this.visibility &&
          other.notes == this.notes);
}

class WorkoutLogsCompanion extends UpdateCompanion<WorkoutLog> {
  final Value<int> localId;
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> userId;
  final Value<String?> routineId;
  final Value<String?> routineNameSnapshot;
  final Value<DateTime> startTime;
  final Value<DateTime?> endTime;
  final Value<String> status;
  final Value<String> visibility;
  final Value<String?> notes;
  const WorkoutLogsCompanion({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.userId = const Value.absent(),
    this.routineId = const Value.absent(),
    this.routineNameSnapshot = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.status = const Value.absent(),
    this.visibility = const Value.absent(),
    this.notes = const Value.absent(),
  });
  WorkoutLogsCompanion.insert({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.userId = const Value.absent(),
    this.routineId = const Value.absent(),
    this.routineNameSnapshot = const Value.absent(),
    required DateTime startTime,
    this.endTime = const Value.absent(),
    this.status = const Value.absent(),
    this.visibility = const Value.absent(),
    this.notes = const Value.absent(),
  }) : startTime = Value(startTime);
  static Insertable<WorkoutLog> custom({
    Expression<int>? localId,
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? userId,
    Expression<String>? routineId,
    Expression<String>? routineNameSnapshot,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<String>? status,
    Expression<String>? visibility,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (userId != null) 'user_id': userId,
      if (routineId != null) 'routine_id': routineId,
      if (routineNameSnapshot != null)
        'routine_name_snapshot': routineNameSnapshot,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (status != null) 'status': status,
      if (visibility != null) 'visibility': visibility,
      if (notes != null) 'notes': notes,
    });
  }

  WorkoutLogsCompanion copyWith(
      {Value<int>? localId,
      Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String?>? userId,
      Value<String?>? routineId,
      Value<String?>? routineNameSnapshot,
      Value<DateTime>? startTime,
      Value<DateTime?>? endTime,
      Value<String>? status,
      Value<String>? visibility,
      Value<String?>? notes}) {
    return WorkoutLogsCompanion(
      localId: localId ?? this.localId,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      userId: userId ?? this.userId,
      routineId: routineId ?? this.routineId,
      routineNameSnapshot: routineNameSnapshot ?? this.routineNameSnapshot,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      visibility: visibility ?? this.visibility,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (routineId.present) {
      map['routine_id'] = Variable<String>(routineId.value);
    }
    if (routineNameSnapshot.present) {
      map['routine_name_snapshot'] =
          Variable<String>(routineNameSnapshot.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (visibility.present) {
      map['visibility'] = Variable<String>(visibility.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutLogsCompanion(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('userId: $userId, ')
          ..write('routineId: $routineId, ')
          ..write('routineNameSnapshot: $routineNameSnapshot, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('status: $status, ')
          ..write('visibility: $visibility, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $SetLogsTable extends SetLogs with TableInfo<$SetLogsTable, SetLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SetLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
      'local_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _workoutLogIdMeta =
      const VerificationMeta('workoutLogId');
  @override
  late final GeneratedColumn<String> workoutLogId = GeneratedColumn<String>(
      'workout_log_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES workout_logs (id) ON DELETE CASCADE'));
  static const VerificationMeta _exerciseIdMeta =
      const VerificationMeta('exerciseId');
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
      'exercise_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES exercises (id)'));
  static const VerificationMeta _exerciseNameSnapshotMeta =
      const VerificationMeta('exerciseNameSnapshot');
  @override
  late final GeneratedColumn<String> exerciseNameSnapshot =
      GeneratedColumn<String>('exercise_name_snapshot', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
      'weight', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
      'reps', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _rpeMeta = const VerificationMeta('rpe');
  @override
  late final GeneratedColumn<int> rpe = GeneratedColumn<int>(
      'rpe', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _rirMeta = const VerificationMeta('rir');
  @override
  late final GeneratedColumn<int> rir = GeneratedColumn<int>(
      'rir', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _setTypeMeta =
      const VerificationMeta('setType');
  @override
  late final GeneratedColumn<String> setType = GeneratedColumn<String>(
      'set_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('normal'));
  static const VerificationMeta _restTimeSecondsMeta =
      const VerificationMeta('restTimeSeconds');
  @override
  late final GeneratedColumn<int> restTimeSeconds = GeneratedColumn<int>(
      'rest_time_seconds', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _isCompletedMeta =
      const VerificationMeta('isCompleted');
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
      'is_completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _logOrderMeta =
      const VerificationMeta('logOrder');
  @override
  late final GeneratedColumn<int> logOrder = GeneratedColumn<int>(
      'log_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _distanceMeta =
      const VerificationMeta('distance');
  @override
  late final GeneratedColumn<double> distance = GeneratedColumn<double>(
      'distance', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
      'duration_seconds', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        id,
        createdAt,
        updatedAt,
        deletedAt,
        workoutLogId,
        exerciseId,
        exerciseNameSnapshot,
        weight,
        reps,
        rpe,
        rir,
        setType,
        restTimeSeconds,
        isCompleted,
        logOrder,
        distance,
        durationSeconds,
        notes
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'set_logs';
  @override
  VerificationContext validateIntegrity(Insertable<SetLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('workout_log_id')) {
      context.handle(
          _workoutLogIdMeta,
          workoutLogId.isAcceptableOrUnknown(
              data['workout_log_id']!, _workoutLogIdMeta));
    } else if (isInserting) {
      context.missing(_workoutLogIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
          _exerciseIdMeta,
          exerciseId.isAcceptableOrUnknown(
              data['exercise_id']!, _exerciseIdMeta));
    }
    if (data.containsKey('exercise_name_snapshot')) {
      context.handle(
          _exerciseNameSnapshotMeta,
          exerciseNameSnapshot.isAcceptableOrUnknown(
              data['exercise_name_snapshot']!, _exerciseNameSnapshotMeta));
    }
    if (data.containsKey('weight')) {
      context.handle(_weightMeta,
          weight.isAcceptableOrUnknown(data['weight']!, _weightMeta));
    }
    if (data.containsKey('reps')) {
      context.handle(
          _repsMeta, reps.isAcceptableOrUnknown(data['reps']!, _repsMeta));
    }
    if (data.containsKey('rpe')) {
      context.handle(
          _rpeMeta, rpe.isAcceptableOrUnknown(data['rpe']!, _rpeMeta));
    }
    if (data.containsKey('rir')) {
      context.handle(
          _rirMeta, rir.isAcceptableOrUnknown(data['rir']!, _rirMeta));
    }
    if (data.containsKey('set_type')) {
      context.handle(_setTypeMeta,
          setType.isAcceptableOrUnknown(data['set_type']!, _setTypeMeta));
    }
    if (data.containsKey('rest_time_seconds')) {
      context.handle(
          _restTimeSecondsMeta,
          restTimeSeconds.isAcceptableOrUnknown(
              data['rest_time_seconds']!, _restTimeSecondsMeta));
    }
    if (data.containsKey('is_completed')) {
      context.handle(
          _isCompletedMeta,
          isCompleted.isAcceptableOrUnknown(
              data['is_completed']!, _isCompletedMeta));
    }
    if (data.containsKey('log_order')) {
      context.handle(_logOrderMeta,
          logOrder.isAcceptableOrUnknown(data['log_order']!, _logOrderMeta));
    }
    if (data.containsKey('distance')) {
      context.handle(_distanceMeta,
          distance.isAcceptableOrUnknown(data['distance']!, _distanceMeta));
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  SetLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SetLog(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}local_id'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      workoutLogId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}workout_log_id'])!,
      exerciseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exercise_id']),
      exerciseNameSnapshot: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}exercise_name_snapshot']),
      weight: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight']),
      reps: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reps']),
      rpe: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rpe']),
      rir: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rir']),
      setType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}set_type'])!,
      restTimeSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rest_time_seconds']),
      isCompleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_completed'])!,
      logOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}log_order'])!,
      distance: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}distance']),
      durationSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_seconds']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
    );
  }

  @override
  $SetLogsTable createAlias(String alias) {
    return $SetLogsTable(attachedDatabase, alias);
  }
}

class SetLog extends DataClass implements Insertable<SetLog> {
  final int localId;
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String workoutLogId;
  final String? exerciseId;
  final String? exerciseNameSnapshot;
  final double? weight;
  final int? reps;
  final int? rpe;
  final int? rir;
  final String setType;
  final int? restTimeSeconds;
  final bool isCompleted;
  final int logOrder;
  final double? distance;
  final int? durationSeconds;
  final String? notes;
  const SetLog(
      {required this.localId,
      required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.workoutLogId,
      this.exerciseId,
      this.exerciseNameSnapshot,
      this.weight,
      this.reps,
      this.rpe,
      this.rir,
      required this.setType,
      this.restTimeSeconds,
      required this.isCompleted,
      required this.logOrder,
      this.distance,
      this.durationSeconds,
      this.notes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['workout_log_id'] = Variable<String>(workoutLogId);
    if (!nullToAbsent || exerciseId != null) {
      map['exercise_id'] = Variable<String>(exerciseId);
    }
    if (!nullToAbsent || exerciseNameSnapshot != null) {
      map['exercise_name_snapshot'] = Variable<String>(exerciseNameSnapshot);
    }
    if (!nullToAbsent || weight != null) {
      map['weight'] = Variable<double>(weight);
    }
    if (!nullToAbsent || reps != null) {
      map['reps'] = Variable<int>(reps);
    }
    if (!nullToAbsent || rpe != null) {
      map['rpe'] = Variable<int>(rpe);
    }
    if (!nullToAbsent || rir != null) {
      map['rir'] = Variable<int>(rir);
    }
    map['set_type'] = Variable<String>(setType);
    if (!nullToAbsent || restTimeSeconds != null) {
      map['rest_time_seconds'] = Variable<int>(restTimeSeconds);
    }
    map['is_completed'] = Variable<bool>(isCompleted);
    map['log_order'] = Variable<int>(logOrder);
    if (!nullToAbsent || distance != null) {
      map['distance'] = Variable<double>(distance);
    }
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  SetLogsCompanion toCompanion(bool nullToAbsent) {
    return SetLogsCompanion(
      localId: Value(localId),
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      workoutLogId: Value(workoutLogId),
      exerciseId: exerciseId == null && nullToAbsent
          ? const Value.absent()
          : Value(exerciseId),
      exerciseNameSnapshot: exerciseNameSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(exerciseNameSnapshot),
      weight:
          weight == null && nullToAbsent ? const Value.absent() : Value(weight),
      reps: reps == null && nullToAbsent ? const Value.absent() : Value(reps),
      rpe: rpe == null && nullToAbsent ? const Value.absent() : Value(rpe),
      rir: rir == null && nullToAbsent ? const Value.absent() : Value(rir),
      setType: Value(setType),
      restTimeSeconds: restTimeSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(restTimeSeconds),
      isCompleted: Value(isCompleted),
      logOrder: Value(logOrder),
      distance: distance == null && nullToAbsent
          ? const Value.absent()
          : Value(distance),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
    );
  }

  factory SetLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SetLog(
      localId: serializer.fromJson<int>(json['localId']),
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      workoutLogId: serializer.fromJson<String>(json['workoutLogId']),
      exerciseId: serializer.fromJson<String?>(json['exerciseId']),
      exerciseNameSnapshot:
          serializer.fromJson<String?>(json['exerciseNameSnapshot']),
      weight: serializer.fromJson<double?>(json['weight']),
      reps: serializer.fromJson<int?>(json['reps']),
      rpe: serializer.fromJson<int?>(json['rpe']),
      rir: serializer.fromJson<int?>(json['rir']),
      setType: serializer.fromJson<String>(json['setType']),
      restTimeSeconds: serializer.fromJson<int?>(json['restTimeSeconds']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      logOrder: serializer.fromJson<int>(json['logOrder']),
      distance: serializer.fromJson<double?>(json['distance']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'workoutLogId': serializer.toJson<String>(workoutLogId),
      'exerciseId': serializer.toJson<String?>(exerciseId),
      'exerciseNameSnapshot': serializer.toJson<String?>(exerciseNameSnapshot),
      'weight': serializer.toJson<double?>(weight),
      'reps': serializer.toJson<int?>(reps),
      'rpe': serializer.toJson<int?>(rpe),
      'rir': serializer.toJson<int?>(rir),
      'setType': serializer.toJson<String>(setType),
      'restTimeSeconds': serializer.toJson<int?>(restTimeSeconds),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'logOrder': serializer.toJson<int>(logOrder),
      'distance': serializer.toJson<double?>(distance),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  SetLog copyWith(
          {int? localId,
          String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? workoutLogId,
          Value<String?> exerciseId = const Value.absent(),
          Value<String?> exerciseNameSnapshot = const Value.absent(),
          Value<double?> weight = const Value.absent(),
          Value<int?> reps = const Value.absent(),
          Value<int?> rpe = const Value.absent(),
          Value<int?> rir = const Value.absent(),
          String? setType,
          Value<int?> restTimeSeconds = const Value.absent(),
          bool? isCompleted,
          int? logOrder,
          Value<double?> distance = const Value.absent(),
          Value<int?> durationSeconds = const Value.absent(),
          Value<String?> notes = const Value.absent()}) =>
      SetLog(
        localId: localId ?? this.localId,
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        workoutLogId: workoutLogId ?? this.workoutLogId,
        exerciseId: exerciseId.present ? exerciseId.value : this.exerciseId,
        exerciseNameSnapshot: exerciseNameSnapshot.present
            ? exerciseNameSnapshot.value
            : this.exerciseNameSnapshot,
        weight: weight.present ? weight.value : this.weight,
        reps: reps.present ? reps.value : this.reps,
        rpe: rpe.present ? rpe.value : this.rpe,
        rir: rir.present ? rir.value : this.rir,
        setType: setType ?? this.setType,
        restTimeSeconds: restTimeSeconds.present
            ? restTimeSeconds.value
            : this.restTimeSeconds,
        isCompleted: isCompleted ?? this.isCompleted,
        logOrder: logOrder ?? this.logOrder,
        distance: distance.present ? distance.value : this.distance,
        durationSeconds: durationSeconds.present
            ? durationSeconds.value
            : this.durationSeconds,
        notes: notes.present ? notes.value : this.notes,
      );
  SetLog copyWithCompanion(SetLogsCompanion data) {
    return SetLog(
      localId: data.localId.present ? data.localId.value : this.localId,
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      workoutLogId: data.workoutLogId.present
          ? data.workoutLogId.value
          : this.workoutLogId,
      exerciseId:
          data.exerciseId.present ? data.exerciseId.value : this.exerciseId,
      exerciseNameSnapshot: data.exerciseNameSnapshot.present
          ? data.exerciseNameSnapshot.value
          : this.exerciseNameSnapshot,
      weight: data.weight.present ? data.weight.value : this.weight,
      reps: data.reps.present ? data.reps.value : this.reps,
      rpe: data.rpe.present ? data.rpe.value : this.rpe,
      rir: data.rir.present ? data.rir.value : this.rir,
      setType: data.setType.present ? data.setType.value : this.setType,
      restTimeSeconds: data.restTimeSeconds.present
          ? data.restTimeSeconds.value
          : this.restTimeSeconds,
      isCompleted:
          data.isCompleted.present ? data.isCompleted.value : this.isCompleted,
      logOrder: data.logOrder.present ? data.logOrder.value : this.logOrder,
      distance: data.distance.present ? data.distance.value : this.distance,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SetLog(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('workoutLogId: $workoutLogId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('exerciseNameSnapshot: $exerciseNameSnapshot, ')
          ..write('weight: $weight, ')
          ..write('reps: $reps, ')
          ..write('rpe: $rpe, ')
          ..write('rir: $rir, ')
          ..write('setType: $setType, ')
          ..write('restTimeSeconds: $restTimeSeconds, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('logOrder: $logOrder, ')
          ..write('distance: $distance, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      localId,
      id,
      createdAt,
      updatedAt,
      deletedAt,
      workoutLogId,
      exerciseId,
      exerciseNameSnapshot,
      weight,
      reps,
      rpe,
      rir,
      setType,
      restTimeSeconds,
      isCompleted,
      logOrder,
      distance,
      durationSeconds,
      notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetLog &&
          other.localId == this.localId &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.workoutLogId == this.workoutLogId &&
          other.exerciseId == this.exerciseId &&
          other.exerciseNameSnapshot == this.exerciseNameSnapshot &&
          other.weight == this.weight &&
          other.reps == this.reps &&
          other.rpe == this.rpe &&
          other.rir == this.rir &&
          other.setType == this.setType &&
          other.restTimeSeconds == this.restTimeSeconds &&
          other.isCompleted == this.isCompleted &&
          other.logOrder == this.logOrder &&
          other.distance == this.distance &&
          other.durationSeconds == this.durationSeconds &&
          other.notes == this.notes);
}

class SetLogsCompanion extends UpdateCompanion<SetLog> {
  final Value<int> localId;
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> workoutLogId;
  final Value<String?> exerciseId;
  final Value<String?> exerciseNameSnapshot;
  final Value<double?> weight;
  final Value<int?> reps;
  final Value<int?> rpe;
  final Value<int?> rir;
  final Value<String> setType;
  final Value<int?> restTimeSeconds;
  final Value<bool> isCompleted;
  final Value<int> logOrder;
  final Value<double?> distance;
  final Value<int?> durationSeconds;
  final Value<String?> notes;
  const SetLogsCompanion({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.workoutLogId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.exerciseNameSnapshot = const Value.absent(),
    this.weight = const Value.absent(),
    this.reps = const Value.absent(),
    this.rpe = const Value.absent(),
    this.rir = const Value.absent(),
    this.setType = const Value.absent(),
    this.restTimeSeconds = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.logOrder = const Value.absent(),
    this.distance = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.notes = const Value.absent(),
  });
  SetLogsCompanion.insert({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String workoutLogId,
    this.exerciseId = const Value.absent(),
    this.exerciseNameSnapshot = const Value.absent(),
    this.weight = const Value.absent(),
    this.reps = const Value.absent(),
    this.rpe = const Value.absent(),
    this.rir = const Value.absent(),
    this.setType = const Value.absent(),
    this.restTimeSeconds = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.logOrder = const Value.absent(),
    this.distance = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.notes = const Value.absent(),
  }) : workoutLogId = Value(workoutLogId);
  static Insertable<SetLog> custom({
    Expression<int>? localId,
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? workoutLogId,
    Expression<String>? exerciseId,
    Expression<String>? exerciseNameSnapshot,
    Expression<double>? weight,
    Expression<int>? reps,
    Expression<int>? rpe,
    Expression<int>? rir,
    Expression<String>? setType,
    Expression<int>? restTimeSeconds,
    Expression<bool>? isCompleted,
    Expression<int>? logOrder,
    Expression<double>? distance,
    Expression<int>? durationSeconds,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (workoutLogId != null) 'workout_log_id': workoutLogId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (exerciseNameSnapshot != null)
        'exercise_name_snapshot': exerciseNameSnapshot,
      if (weight != null) 'weight': weight,
      if (reps != null) 'reps': reps,
      if (rpe != null) 'rpe': rpe,
      if (rir != null) 'rir': rir,
      if (setType != null) 'set_type': setType,
      if (restTimeSeconds != null) 'rest_time_seconds': restTimeSeconds,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (logOrder != null) 'log_order': logOrder,
      if (distance != null) 'distance': distance,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (notes != null) 'notes': notes,
    });
  }

  SetLogsCompanion copyWith(
      {Value<int>? localId,
      Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? workoutLogId,
      Value<String?>? exerciseId,
      Value<String?>? exerciseNameSnapshot,
      Value<double?>? weight,
      Value<int?>? reps,
      Value<int?>? rpe,
      Value<int?>? rir,
      Value<String>? setType,
      Value<int?>? restTimeSeconds,
      Value<bool>? isCompleted,
      Value<int>? logOrder,
      Value<double?>? distance,
      Value<int?>? durationSeconds,
      Value<String?>? notes}) {
    return SetLogsCompanion(
      localId: localId ?? this.localId,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      workoutLogId: workoutLogId ?? this.workoutLogId,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseNameSnapshot: exerciseNameSnapshot ?? this.exerciseNameSnapshot,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      rpe: rpe ?? this.rpe,
      rir: rir ?? this.rir,
      setType: setType ?? this.setType,
      restTimeSeconds: restTimeSeconds ?? this.restTimeSeconds,
      isCompleted: isCompleted ?? this.isCompleted,
      logOrder: logOrder ?? this.logOrder,
      distance: distance ?? this.distance,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (workoutLogId.present) {
      map['workout_log_id'] = Variable<String>(workoutLogId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (exerciseNameSnapshot.present) {
      map['exercise_name_snapshot'] =
          Variable<String>(exerciseNameSnapshot.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (rpe.present) {
      map['rpe'] = Variable<int>(rpe.value);
    }
    if (rir.present) {
      map['rir'] = Variable<int>(rir.value);
    }
    if (setType.present) {
      map['set_type'] = Variable<String>(setType.value);
    }
    if (restTimeSeconds.present) {
      map['rest_time_seconds'] = Variable<int>(restTimeSeconds.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (logOrder.present) {
      map['log_order'] = Variable<int>(logOrder.value);
    }
    if (distance.present) {
      map['distance'] = Variable<double>(distance.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SetLogsCompanion(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('workoutLogId: $workoutLogId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('exerciseNameSnapshot: $exerciseNameSnapshot, ')
          ..write('weight: $weight, ')
          ..write('reps: $reps, ')
          ..write('rpe: $rpe, ')
          ..write('rir: $rir, ')
          ..write('setType: $setType, ')
          ..write('restTimeSeconds: $restTimeSeconds, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('logOrder: $logOrder, ')
          ..write('distance: $distance, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $CardioActivitiesTable extends CardioActivities
    with TableInfo<$CardioActivitiesTable, CardioActivity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardioActivitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
      'local_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _workoutLogIdMeta =
      const VerificationMeta('workoutLogId');
  @override
  late final GeneratedColumn<String> workoutLogId = GeneratedColumn<String>(
      'workout_log_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES workout_logs (id) ON DELETE CASCADE'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _distanceMeta =
      const VerificationMeta('distance');
  @override
  late final GeneratedColumn<double> distance = GeneratedColumn<double>(
      'distance', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
      'duration_seconds', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _kcalMeta = const VerificationMeta('kcal');
  @override
  late final GeneratedColumn<int> kcal = GeneratedColumn<int>(
      'kcal', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        id,
        createdAt,
        updatedAt,
        deletedAt,
        workoutLogId,
        type,
        distance,
        durationSeconds,
        kcal,
        source
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cardio_activities';
  @override
  VerificationContext validateIntegrity(Insertable<CardioActivity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('workout_log_id')) {
      context.handle(
          _workoutLogIdMeta,
          workoutLogId.isAcceptableOrUnknown(
              data['workout_log_id']!, _workoutLogIdMeta));
    } else if (isInserting) {
      context.missing(_workoutLogIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('distance')) {
      context.handle(_distanceMeta,
          distance.isAcceptableOrUnknown(data['distance']!, _distanceMeta));
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    }
    if (data.containsKey('kcal')) {
      context.handle(
          _kcalMeta, kcal.isAcceptableOrUnknown(data['kcal']!, _kcalMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  CardioActivity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardioActivity(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}local_id'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      workoutLogId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}workout_log_id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      distance: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}distance']),
      durationSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_seconds']),
      kcal: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}kcal']),
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source']),
    );
  }

  @override
  $CardioActivitiesTable createAlias(String alias) {
    return $CardioActivitiesTable(attachedDatabase, alias);
  }
}

class CardioActivity extends DataClass implements Insertable<CardioActivity> {
  final int localId;
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String workoutLogId;
  final String type;
  final double? distance;
  final int? durationSeconds;
  final int? kcal;
  final String? source;
  const CardioActivity(
      {required this.localId,
      required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.workoutLogId,
      required this.type,
      this.distance,
      this.durationSeconds,
      this.kcal,
      this.source});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['workout_log_id'] = Variable<String>(workoutLogId);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || distance != null) {
      map['distance'] = Variable<double>(distance);
    }
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    if (!nullToAbsent || kcal != null) {
      map['kcal'] = Variable<int>(kcal);
    }
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    return map;
  }

  CardioActivitiesCompanion toCompanion(bool nullToAbsent) {
    return CardioActivitiesCompanion(
      localId: Value(localId),
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      workoutLogId: Value(workoutLogId),
      type: Value(type),
      distance: distance == null && nullToAbsent
          ? const Value.absent()
          : Value(distance),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      kcal: kcal == null && nullToAbsent ? const Value.absent() : Value(kcal),
      source:
          source == null && nullToAbsent ? const Value.absent() : Value(source),
    );
  }

  factory CardioActivity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardioActivity(
      localId: serializer.fromJson<int>(json['localId']),
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      workoutLogId: serializer.fromJson<String>(json['workoutLogId']),
      type: serializer.fromJson<String>(json['type']),
      distance: serializer.fromJson<double?>(json['distance']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      kcal: serializer.fromJson<int?>(json['kcal']),
      source: serializer.fromJson<String?>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'workoutLogId': serializer.toJson<String>(workoutLogId),
      'type': serializer.toJson<String>(type),
      'distance': serializer.toJson<double?>(distance),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'kcal': serializer.toJson<int?>(kcal),
      'source': serializer.toJson<String?>(source),
    };
  }

  CardioActivity copyWith(
          {int? localId,
          String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? workoutLogId,
          String? type,
          Value<double?> distance = const Value.absent(),
          Value<int?> durationSeconds = const Value.absent(),
          Value<int?> kcal = const Value.absent(),
          Value<String?> source = const Value.absent()}) =>
      CardioActivity(
        localId: localId ?? this.localId,
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        workoutLogId: workoutLogId ?? this.workoutLogId,
        type: type ?? this.type,
        distance: distance.present ? distance.value : this.distance,
        durationSeconds: durationSeconds.present
            ? durationSeconds.value
            : this.durationSeconds,
        kcal: kcal.present ? kcal.value : this.kcal,
        source: source.present ? source.value : this.source,
      );
  CardioActivity copyWithCompanion(CardioActivitiesCompanion data) {
    return CardioActivity(
      localId: data.localId.present ? data.localId.value : this.localId,
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      workoutLogId: data.workoutLogId.present
          ? data.workoutLogId.value
          : this.workoutLogId,
      type: data.type.present ? data.type.value : this.type,
      distance: data.distance.present ? data.distance.value : this.distance,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      kcal: data.kcal.present ? data.kcal.value : this.kcal,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardioActivity(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('workoutLogId: $workoutLogId, ')
          ..write('type: $type, ')
          ..write('distance: $distance, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('kcal: $kcal, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(localId, id, createdAt, updatedAt, deletedAt,
      workoutLogId, type, distance, durationSeconds, kcal, source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardioActivity &&
          other.localId == this.localId &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.workoutLogId == this.workoutLogId &&
          other.type == this.type &&
          other.distance == this.distance &&
          other.durationSeconds == this.durationSeconds &&
          other.kcal == this.kcal &&
          other.source == this.source);
}

class CardioActivitiesCompanion extends UpdateCompanion<CardioActivity> {
  final Value<int> localId;
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> workoutLogId;
  final Value<String> type;
  final Value<double?> distance;
  final Value<int?> durationSeconds;
  final Value<int?> kcal;
  final Value<String?> source;
  const CardioActivitiesCompanion({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.workoutLogId = const Value.absent(),
    this.type = const Value.absent(),
    this.distance = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.kcal = const Value.absent(),
    this.source = const Value.absent(),
  });
  CardioActivitiesCompanion.insert({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String workoutLogId,
    required String type,
    this.distance = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.kcal = const Value.absent(),
    this.source = const Value.absent(),
  })  : workoutLogId = Value(workoutLogId),
        type = Value(type);
  static Insertable<CardioActivity> custom({
    Expression<int>? localId,
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? workoutLogId,
    Expression<String>? type,
    Expression<double>? distance,
    Expression<int>? durationSeconds,
    Expression<int>? kcal,
    Expression<String>? source,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (workoutLogId != null) 'workout_log_id': workoutLogId,
      if (type != null) 'type': type,
      if (distance != null) 'distance': distance,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (kcal != null) 'kcal': kcal,
      if (source != null) 'source': source,
    });
  }

  CardioActivitiesCompanion copyWith(
      {Value<int>? localId,
      Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? workoutLogId,
      Value<String>? type,
      Value<double?>? distance,
      Value<int?>? durationSeconds,
      Value<int?>? kcal,
      Value<String?>? source}) {
    return CardioActivitiesCompanion(
      localId: localId ?? this.localId,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      workoutLogId: workoutLogId ?? this.workoutLogId,
      type: type ?? this.type,
      distance: distance ?? this.distance,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      kcal: kcal ?? this.kcal,
      source: source ?? this.source,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (workoutLogId.present) {
      map['workout_log_id'] = Variable<String>(workoutLogId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (distance.present) {
      map['distance'] = Variable<double>(distance.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (kcal.present) {
      map['kcal'] = Variable<int>(kcal.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardioActivitiesCompanion(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('workoutLogId: $workoutLogId, ')
          ..write('type: $type, ')
          ..write('distance: $distance, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('kcal: $kcal, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }
}

class $CardioSamplesTable extends CardioSamples
    with TableInfo<$CardioSamplesTable, CardioSample> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardioSamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
      'local_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _cardioActivityIdMeta =
      const VerificationMeta('cardioActivityId');
  @override
  late final GeneratedColumn<String> cardioActivityId = GeneratedColumn<String>(
      'cardio_activity_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES cardio_activities (id) ON DELETE CASCADE'));
  static const VerificationMeta _dataTypeMeta =
      const VerificationMeta('dataType');
  @override
  late final GeneratedColumn<String> dataType = GeneratedColumn<String>(
      'data_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataJsonMeta =
      const VerificationMeta('dataJson');
  @override
  late final GeneratedColumn<String> dataJson = GeneratedColumn<String>(
      'data_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        id,
        createdAt,
        updatedAt,
        deletedAt,
        cardioActivityId,
        dataType,
        dataJson
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cardio_samples';
  @override
  VerificationContext validateIntegrity(Insertable<CardioSample> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('cardio_activity_id')) {
      context.handle(
          _cardioActivityIdMeta,
          cardioActivityId.isAcceptableOrUnknown(
              data['cardio_activity_id']!, _cardioActivityIdMeta));
    } else if (isInserting) {
      context.missing(_cardioActivityIdMeta);
    }
    if (data.containsKey('data_type')) {
      context.handle(_dataTypeMeta,
          dataType.isAcceptableOrUnknown(data['data_type']!, _dataTypeMeta));
    } else if (isInserting) {
      context.missing(_dataTypeMeta);
    }
    if (data.containsKey('data_json')) {
      context.handle(_dataJsonMeta,
          dataJson.isAcceptableOrUnknown(data['data_json']!, _dataJsonMeta));
    } else if (isInserting) {
      context.missing(_dataJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  CardioSample map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardioSample(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}local_id'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      cardioActivityId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}cardio_activity_id'])!,
      dataType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data_type'])!,
      dataJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data_json'])!,
    );
  }

  @override
  $CardioSamplesTable createAlias(String alias) {
    return $CardioSamplesTable(attachedDatabase, alias);
  }
}

class CardioSample extends DataClass implements Insertable<CardioSample> {
  final int localId;
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String cardioActivityId;
  final String dataType;
  final String dataJson;
  const CardioSample(
      {required this.localId,
      required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.cardioActivityId,
      required this.dataType,
      required this.dataJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['cardio_activity_id'] = Variable<String>(cardioActivityId);
    map['data_type'] = Variable<String>(dataType);
    map['data_json'] = Variable<String>(dataJson);
    return map;
  }

  CardioSamplesCompanion toCompanion(bool nullToAbsent) {
    return CardioSamplesCompanion(
      localId: Value(localId),
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      cardioActivityId: Value(cardioActivityId),
      dataType: Value(dataType),
      dataJson: Value(dataJson),
    );
  }

  factory CardioSample.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardioSample(
      localId: serializer.fromJson<int>(json['localId']),
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      cardioActivityId: serializer.fromJson<String>(json['cardioActivityId']),
      dataType: serializer.fromJson<String>(json['dataType']),
      dataJson: serializer.fromJson<String>(json['dataJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'cardioActivityId': serializer.toJson<String>(cardioActivityId),
      'dataType': serializer.toJson<String>(dataType),
      'dataJson': serializer.toJson<String>(dataJson),
    };
  }

  CardioSample copyWith(
          {int? localId,
          String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? cardioActivityId,
          String? dataType,
          String? dataJson}) =>
      CardioSample(
        localId: localId ?? this.localId,
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        cardioActivityId: cardioActivityId ?? this.cardioActivityId,
        dataType: dataType ?? this.dataType,
        dataJson: dataJson ?? this.dataJson,
      );
  CardioSample copyWithCompanion(CardioSamplesCompanion data) {
    return CardioSample(
      localId: data.localId.present ? data.localId.value : this.localId,
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      cardioActivityId: data.cardioActivityId.present
          ? data.cardioActivityId.value
          : this.cardioActivityId,
      dataType: data.dataType.present ? data.dataType.value : this.dataType,
      dataJson: data.dataJson.present ? data.dataJson.value : this.dataJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardioSample(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('cardioActivityId: $cardioActivityId, ')
          ..write('dataType: $dataType, ')
          ..write('dataJson: $dataJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(localId, id, createdAt, updatedAt, deletedAt,
      cardioActivityId, dataType, dataJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardioSample &&
          other.localId == this.localId &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.cardioActivityId == this.cardioActivityId &&
          other.dataType == this.dataType &&
          other.dataJson == this.dataJson);
}

class CardioSamplesCompanion extends UpdateCompanion<CardioSample> {
  final Value<int> localId;
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> cardioActivityId;
  final Value<String> dataType;
  final Value<String> dataJson;
  const CardioSamplesCompanion({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.cardioActivityId = const Value.absent(),
    this.dataType = const Value.absent(),
    this.dataJson = const Value.absent(),
  });
  CardioSamplesCompanion.insert({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String cardioActivityId,
    required String dataType,
    required String dataJson,
  })  : cardioActivityId = Value(cardioActivityId),
        dataType = Value(dataType),
        dataJson = Value(dataJson);
  static Insertable<CardioSample> custom({
    Expression<int>? localId,
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? cardioActivityId,
    Expression<String>? dataType,
    Expression<String>? dataJson,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (cardioActivityId != null) 'cardio_activity_id': cardioActivityId,
      if (dataType != null) 'data_type': dataType,
      if (dataJson != null) 'data_json': dataJson,
    });
  }

  CardioSamplesCompanion copyWith(
      {Value<int>? localId,
      Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? cardioActivityId,
      Value<String>? dataType,
      Value<String>? dataJson}) {
    return CardioSamplesCompanion(
      localId: localId ?? this.localId,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      cardioActivityId: cardioActivityId ?? this.cardioActivityId,
      dataType: dataType ?? this.dataType,
      dataJson: dataJson ?? this.dataJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (cardioActivityId.present) {
      map['cardio_activity_id'] = Variable<String>(cardioActivityId.value);
    }
    if (dataType.present) {
      map['data_type'] = Variable<String>(dataType.value);
    }
    if (dataJson.present) {
      map['data_json'] = Variable<String>(dataJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardioSamplesCompanion(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('cardioActivityId: $cardioActivityId, ')
          ..write('dataType: $dataType, ')
          ..write('dataJson: $dataJson')
          ..write(')'))
        .toString();
  }
}

class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
      'local_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _barcodeMeta =
      const VerificationMeta('barcode');
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
      'barcode', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
      'brand', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _caloriesMeta =
      const VerificationMeta('calories');
  @override
  late final GeneratedColumn<int> calories = GeneratedColumn<int>(
      'calories', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _proteinMeta =
      const VerificationMeta('protein');
  @override
  late final GeneratedColumn<double> protein = GeneratedColumn<double>(
      'protein', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _carbsMeta = const VerificationMeta('carbs');
  @override
  late final GeneratedColumn<double> carbs = GeneratedColumn<double>(
      'carbs', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _fatMeta = const VerificationMeta('fat');
  @override
  late final GeneratedColumn<double> fat = GeneratedColumn<double>(
      'fat', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _sugarMeta = const VerificationMeta('sugar');
  @override
  late final GeneratedColumn<double> sugar = GeneratedColumn<double>(
      'sugar', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _fiberMeta = const VerificationMeta('fiber');
  @override
  late final GeneratedColumn<double> fiber = GeneratedColumn<double>(
      'fiber', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _saltMeta = const VerificationMeta('salt');
  @override
  late final GeneratedColumn<double> salt = GeneratedColumn<double>(
      'salt', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _caffeineMeta =
      const VerificationMeta('caffeine');
  @override
  late final GeneratedColumn<double> caffeine = GeneratedColumn<double>(
      'caffeine', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _isLiquidMeta =
      const VerificationMeta('isLiquid');
  @override
  late final GeneratedColumn<bool> isLiquid = GeneratedColumn<bool>(
      'is_liquid', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_liquid" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('user'));
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        id,
        createdAt,
        updatedAt,
        deletedAt,
        barcode,
        name,
        brand,
        calories,
        protein,
        carbs,
        fat,
        sugar,
        fiber,
        salt,
        caffeine,
        isLiquid,
        source,
        category
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(Insertable<Product> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('barcode')) {
      context.handle(_barcodeMeta,
          barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta));
    } else if (isInserting) {
      context.missing(_barcodeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
          _brandMeta, brand.isAcceptableOrUnknown(data['brand']!, _brandMeta));
    }
    if (data.containsKey('calories')) {
      context.handle(_caloriesMeta,
          calories.isAcceptableOrUnknown(data['calories']!, _caloriesMeta));
    } else if (isInserting) {
      context.missing(_caloriesMeta);
    }
    if (data.containsKey('protein')) {
      context.handle(_proteinMeta,
          protein.isAcceptableOrUnknown(data['protein']!, _proteinMeta));
    } else if (isInserting) {
      context.missing(_proteinMeta);
    }
    if (data.containsKey('carbs')) {
      context.handle(
          _carbsMeta, carbs.isAcceptableOrUnknown(data['carbs']!, _carbsMeta));
    } else if (isInserting) {
      context.missing(_carbsMeta);
    }
    if (data.containsKey('fat')) {
      context.handle(
          _fatMeta, fat.isAcceptableOrUnknown(data['fat']!, _fatMeta));
    } else if (isInserting) {
      context.missing(_fatMeta);
    }
    if (data.containsKey('sugar')) {
      context.handle(
          _sugarMeta, sugar.isAcceptableOrUnknown(data['sugar']!, _sugarMeta));
    }
    if (data.containsKey('fiber')) {
      context.handle(
          _fiberMeta, fiber.isAcceptableOrUnknown(data['fiber']!, _fiberMeta));
    }
    if (data.containsKey('salt')) {
      context.handle(
          _saltMeta, salt.isAcceptableOrUnknown(data['salt']!, _saltMeta));
    }
    if (data.containsKey('caffeine')) {
      context.handle(_caffeineMeta,
          caffeine.isAcceptableOrUnknown(data['caffeine']!, _caffeineMeta));
    }
    if (data.containsKey('is_liquid')) {
      context.handle(_isLiquidMeta,
          isLiquid.isAcceptableOrUnknown(data['is_liquid']!, _isLiquidMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}local_id'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      barcode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}barcode'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      brand: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}brand']),
      calories: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}calories'])!,
      protein: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}protein'])!,
      carbs: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}carbs'])!,
      fat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}fat'])!,
      sugar: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}sugar']),
      fiber: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}fiber']),
      salt: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}salt']),
      caffeine: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}caffeine']),
      isLiquid: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_liquid'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class Product extends DataClass implements Insertable<Product> {
  final int localId;
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String barcode;
  final String name;
  final String? brand;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? sugar;
  final double? fiber;
  final double? salt;
  final double? caffeine;
  final bool isLiquid;
  final String source;
  final String? category;
  const Product(
      {required this.localId,
      required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.barcode,
      required this.name,
      this.brand,
      required this.calories,
      required this.protein,
      required this.carbs,
      required this.fat,
      this.sugar,
      this.fiber,
      this.salt,
      this.caffeine,
      required this.isLiquid,
      required this.source,
      this.category});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['barcode'] = Variable<String>(barcode);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    map['calories'] = Variable<int>(calories);
    map['protein'] = Variable<double>(protein);
    map['carbs'] = Variable<double>(carbs);
    map['fat'] = Variable<double>(fat);
    if (!nullToAbsent || sugar != null) {
      map['sugar'] = Variable<double>(sugar);
    }
    if (!nullToAbsent || fiber != null) {
      map['fiber'] = Variable<double>(fiber);
    }
    if (!nullToAbsent || salt != null) {
      map['salt'] = Variable<double>(salt);
    }
    if (!nullToAbsent || caffeine != null) {
      map['caffeine'] = Variable<double>(caffeine);
    }
    map['is_liquid'] = Variable<bool>(isLiquid);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      localId: Value(localId),
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      barcode: Value(barcode),
      name: Value(name),
      brand:
          brand == null && nullToAbsent ? const Value.absent() : Value(brand),
      calories: Value(calories),
      protein: Value(protein),
      carbs: Value(carbs),
      fat: Value(fat),
      sugar:
          sugar == null && nullToAbsent ? const Value.absent() : Value(sugar),
      fiber:
          fiber == null && nullToAbsent ? const Value.absent() : Value(fiber),
      salt: salt == null && nullToAbsent ? const Value.absent() : Value(salt),
      caffeine: caffeine == null && nullToAbsent
          ? const Value.absent()
          : Value(caffeine),
      isLiquid: Value(isLiquid),
      source: Value(source),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
    );
  }

  factory Product.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      localId: serializer.fromJson<int>(json['localId']),
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      barcode: serializer.fromJson<String>(json['barcode']),
      name: serializer.fromJson<String>(json['name']),
      brand: serializer.fromJson<String?>(json['brand']),
      calories: serializer.fromJson<int>(json['calories']),
      protein: serializer.fromJson<double>(json['protein']),
      carbs: serializer.fromJson<double>(json['carbs']),
      fat: serializer.fromJson<double>(json['fat']),
      sugar: serializer.fromJson<double?>(json['sugar']),
      fiber: serializer.fromJson<double?>(json['fiber']),
      salt: serializer.fromJson<double?>(json['salt']),
      caffeine: serializer.fromJson<double?>(json['caffeine']),
      isLiquid: serializer.fromJson<bool>(json['isLiquid']),
      source: serializer.fromJson<String>(json['source']),
      category: serializer.fromJson<String?>(json['category']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'barcode': serializer.toJson<String>(barcode),
      'name': serializer.toJson<String>(name),
      'brand': serializer.toJson<String?>(brand),
      'calories': serializer.toJson<int>(calories),
      'protein': serializer.toJson<double>(protein),
      'carbs': serializer.toJson<double>(carbs),
      'fat': serializer.toJson<double>(fat),
      'sugar': serializer.toJson<double?>(sugar),
      'fiber': serializer.toJson<double?>(fiber),
      'salt': serializer.toJson<double?>(salt),
      'caffeine': serializer.toJson<double?>(caffeine),
      'isLiquid': serializer.toJson<bool>(isLiquid),
      'source': serializer.toJson<String>(source),
      'category': serializer.toJson<String?>(category),
    };
  }

  Product copyWith(
          {int? localId,
          String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? barcode,
          String? name,
          Value<String?> brand = const Value.absent(),
          int? calories,
          double? protein,
          double? carbs,
          double? fat,
          Value<double?> sugar = const Value.absent(),
          Value<double?> fiber = const Value.absent(),
          Value<double?> salt = const Value.absent(),
          Value<double?> caffeine = const Value.absent(),
          bool? isLiquid,
          String? source,
          Value<String?> category = const Value.absent()}) =>
      Product(
        localId: localId ?? this.localId,
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        barcode: barcode ?? this.barcode,
        name: name ?? this.name,
        brand: brand.present ? brand.value : this.brand,
        calories: calories ?? this.calories,
        protein: protein ?? this.protein,
        carbs: carbs ?? this.carbs,
        fat: fat ?? this.fat,
        sugar: sugar.present ? sugar.value : this.sugar,
        fiber: fiber.present ? fiber.value : this.fiber,
        salt: salt.present ? salt.value : this.salt,
        caffeine: caffeine.present ? caffeine.value : this.caffeine,
        isLiquid: isLiquid ?? this.isLiquid,
        source: source ?? this.source,
        category: category.present ? category.value : this.category,
      );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      localId: data.localId.present ? data.localId.value : this.localId,
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      name: data.name.present ? data.name.value : this.name,
      brand: data.brand.present ? data.brand.value : this.brand,
      calories: data.calories.present ? data.calories.value : this.calories,
      protein: data.protein.present ? data.protein.value : this.protein,
      carbs: data.carbs.present ? data.carbs.value : this.carbs,
      fat: data.fat.present ? data.fat.value : this.fat,
      sugar: data.sugar.present ? data.sugar.value : this.sugar,
      fiber: data.fiber.present ? data.fiber.value : this.fiber,
      salt: data.salt.present ? data.salt.value : this.salt,
      caffeine: data.caffeine.present ? data.caffeine.value : this.caffeine,
      isLiquid: data.isLiquid.present ? data.isLiquid.value : this.isLiquid,
      source: data.source.present ? data.source.value : this.source,
      category: data.category.present ? data.category.value : this.category,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('barcode: $barcode, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('calories: $calories, ')
          ..write('protein: $protein, ')
          ..write('carbs: $carbs, ')
          ..write('fat: $fat, ')
          ..write('sugar: $sugar, ')
          ..write('fiber: $fiber, ')
          ..write('salt: $salt, ')
          ..write('caffeine: $caffeine, ')
          ..write('isLiquid: $isLiquid, ')
          ..write('source: $source, ')
          ..write('category: $category')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      localId,
      id,
      createdAt,
      updatedAt,
      deletedAt,
      barcode,
      name,
      brand,
      calories,
      protein,
      carbs,
      fat,
      sugar,
      fiber,
      salt,
      caffeine,
      isLiquid,
      source,
      category);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.localId == this.localId &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.barcode == this.barcode &&
          other.name == this.name &&
          other.brand == this.brand &&
          other.calories == this.calories &&
          other.protein == this.protein &&
          other.carbs == this.carbs &&
          other.fat == this.fat &&
          other.sugar == this.sugar &&
          other.fiber == this.fiber &&
          other.salt == this.salt &&
          other.caffeine == this.caffeine &&
          other.isLiquid == this.isLiquid &&
          other.source == this.source &&
          other.category == this.category);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<int> localId;
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> barcode;
  final Value<String> name;
  final Value<String?> brand;
  final Value<int> calories;
  final Value<double> protein;
  final Value<double> carbs;
  final Value<double> fat;
  final Value<double?> sugar;
  final Value<double?> fiber;
  final Value<double?> salt;
  final Value<double?> caffeine;
  final Value<bool> isLiquid;
  final Value<String> source;
  final Value<String?> category;
  const ProductsCompanion({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.barcode = const Value.absent(),
    this.name = const Value.absent(),
    this.brand = const Value.absent(),
    this.calories = const Value.absent(),
    this.protein = const Value.absent(),
    this.carbs = const Value.absent(),
    this.fat = const Value.absent(),
    this.sugar = const Value.absent(),
    this.fiber = const Value.absent(),
    this.salt = const Value.absent(),
    this.caffeine = const Value.absent(),
    this.isLiquid = const Value.absent(),
    this.source = const Value.absent(),
    this.category = const Value.absent(),
  });
  ProductsCompanion.insert({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String barcode,
    required String name,
    this.brand = const Value.absent(),
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
    this.sugar = const Value.absent(),
    this.fiber = const Value.absent(),
    this.salt = const Value.absent(),
    this.caffeine = const Value.absent(),
    this.isLiquid = const Value.absent(),
    this.source = const Value.absent(),
    this.category = const Value.absent(),
  })  : barcode = Value(barcode),
        name = Value(name),
        calories = Value(calories),
        protein = Value(protein),
        carbs = Value(carbs),
        fat = Value(fat);
  static Insertable<Product> custom({
    Expression<int>? localId,
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? barcode,
    Expression<String>? name,
    Expression<String>? brand,
    Expression<int>? calories,
    Expression<double>? protein,
    Expression<double>? carbs,
    Expression<double>? fat,
    Expression<double>? sugar,
    Expression<double>? fiber,
    Expression<double>? salt,
    Expression<double>? caffeine,
    Expression<bool>? isLiquid,
    Expression<String>? source,
    Expression<String>? category,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (barcode != null) 'barcode': barcode,
      if (name != null) 'name': name,
      if (brand != null) 'brand': brand,
      if (calories != null) 'calories': calories,
      if (protein != null) 'protein': protein,
      if (carbs != null) 'carbs': carbs,
      if (fat != null) 'fat': fat,
      if (sugar != null) 'sugar': sugar,
      if (fiber != null) 'fiber': fiber,
      if (salt != null) 'salt': salt,
      if (caffeine != null) 'caffeine': caffeine,
      if (isLiquid != null) 'is_liquid': isLiquid,
      if (source != null) 'source': source,
      if (category != null) 'category': category,
    });
  }

  ProductsCompanion copyWith(
      {Value<int>? localId,
      Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? barcode,
      Value<String>? name,
      Value<String?>? brand,
      Value<int>? calories,
      Value<double>? protein,
      Value<double>? carbs,
      Value<double>? fat,
      Value<double?>? sugar,
      Value<double?>? fiber,
      Value<double?>? salt,
      Value<double?>? caffeine,
      Value<bool>? isLiquid,
      Value<String>? source,
      Value<String?>? category}) {
    return ProductsCompanion(
      localId: localId ?? this.localId,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      sugar: sugar ?? this.sugar,
      fiber: fiber ?? this.fiber,
      salt: salt ?? this.salt,
      caffeine: caffeine ?? this.caffeine,
      isLiquid: isLiquid ?? this.isLiquid,
      source: source ?? this.source,
      category: category ?? this.category,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (calories.present) {
      map['calories'] = Variable<int>(calories.value);
    }
    if (protein.present) {
      map['protein'] = Variable<double>(protein.value);
    }
    if (carbs.present) {
      map['carbs'] = Variable<double>(carbs.value);
    }
    if (fat.present) {
      map['fat'] = Variable<double>(fat.value);
    }
    if (sugar.present) {
      map['sugar'] = Variable<double>(sugar.value);
    }
    if (fiber.present) {
      map['fiber'] = Variable<double>(fiber.value);
    }
    if (salt.present) {
      map['salt'] = Variable<double>(salt.value);
    }
    if (caffeine.present) {
      map['caffeine'] = Variable<double>(caffeine.value);
    }
    if (isLiquid.present) {
      map['is_liquid'] = Variable<bool>(isLiquid.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('barcode: $barcode, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('calories: $calories, ')
          ..write('protein: $protein, ')
          ..write('carbs: $carbs, ')
          ..write('fat: $fat, ')
          ..write('sugar: $sugar, ')
          ..write('fiber: $fiber, ')
          ..write('salt: $salt, ')
          ..write('caffeine: $caffeine, ')
          ..write('isLiquid: $isLiquid, ')
          ..write('source: $source, ')
          ..write('category: $category')
          ..write(')'))
        .toString();
  }
}

class $NutritionLogsTable extends NutritionLogs
    with TableInfo<$NutritionLogsTable, NutritionLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NutritionLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
      'local_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES products (id)'));
  static const VerificationMeta _legacyBarcodeMeta =
      const VerificationMeta('legacyBarcode');
  @override
  late final GeneratedColumn<String> legacyBarcode = GeneratedColumn<String>(
      'legacy_barcode', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _consumedAtMeta =
      const VerificationMeta('consumedAt');
  @override
  late final GeneratedColumn<DateTime> consumedAt = GeneratedColumn<DateTime>(
      'consumed_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _mealTypeMeta =
      const VerificationMeta('mealType');
  @override
  late final GeneratedColumn<String> mealType = GeneratedColumn<String>(
      'meal_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Snack'));
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        id,
        createdAt,
        updatedAt,
        deletedAt,
        userId,
        productId,
        legacyBarcode,
        consumedAt,
        amount,
        mealType
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nutrition_logs';
  @override
  VerificationContext validateIntegrity(Insertable<NutritionLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    }
    if (data.containsKey('legacy_barcode')) {
      context.handle(
          _legacyBarcodeMeta,
          legacyBarcode.isAcceptableOrUnknown(
              data['legacy_barcode']!, _legacyBarcodeMeta));
    }
    if (data.containsKey('consumed_at')) {
      context.handle(
          _consumedAtMeta,
          consumedAt.isAcceptableOrUnknown(
              data['consumed_at']!, _consumedAtMeta));
    } else if (isInserting) {
      context.missing(_consumedAtMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('meal_type')) {
      context.handle(_mealTypeMeta,
          mealType.isAcceptableOrUnknown(data['meal_type']!, _mealTypeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  NutritionLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NutritionLog(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}local_id'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id']),
      legacyBarcode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}legacy_barcode']),
      consumedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}consumed_at'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      mealType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meal_type'])!,
    );
  }

  @override
  $NutritionLogsTable createAlias(String alias) {
    return $NutritionLogsTable(attachedDatabase, alias);
  }
}

class NutritionLog extends DataClass implements Insertable<NutritionLog> {
  final int localId;
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? userId;
  final String? productId;
  final String? legacyBarcode;
  final DateTime consumedAt;
  final double amount;
  final String mealType;
  const NutritionLog(
      {required this.localId,
      required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      this.userId,
      this.productId,
      this.legacyBarcode,
      required this.consumedAt,
      required this.amount,
      required this.mealType});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<String>(productId);
    }
    if (!nullToAbsent || legacyBarcode != null) {
      map['legacy_barcode'] = Variable<String>(legacyBarcode);
    }
    map['consumed_at'] = Variable<DateTime>(consumedAt);
    map['amount'] = Variable<double>(amount);
    map['meal_type'] = Variable<String>(mealType);
    return map;
  }

  NutritionLogsCompanion toCompanion(bool nullToAbsent) {
    return NutritionLogsCompanion(
      localId: Value(localId),
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      legacyBarcode: legacyBarcode == null && nullToAbsent
          ? const Value.absent()
          : Value(legacyBarcode),
      consumedAt: Value(consumedAt),
      amount: Value(amount),
      mealType: Value(mealType),
    );
  }

  factory NutritionLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NutritionLog(
      localId: serializer.fromJson<int>(json['localId']),
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      userId: serializer.fromJson<String?>(json['userId']),
      productId: serializer.fromJson<String?>(json['productId']),
      legacyBarcode: serializer.fromJson<String?>(json['legacyBarcode']),
      consumedAt: serializer.fromJson<DateTime>(json['consumedAt']),
      amount: serializer.fromJson<double>(json['amount']),
      mealType: serializer.fromJson<String>(json['mealType']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'userId': serializer.toJson<String?>(userId),
      'productId': serializer.toJson<String?>(productId),
      'legacyBarcode': serializer.toJson<String?>(legacyBarcode),
      'consumedAt': serializer.toJson<DateTime>(consumedAt),
      'amount': serializer.toJson<double>(amount),
      'mealType': serializer.toJson<String>(mealType),
    };
  }

  NutritionLog copyWith(
          {int? localId,
          String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          Value<String?> userId = const Value.absent(),
          Value<String?> productId = const Value.absent(),
          Value<String?> legacyBarcode = const Value.absent(),
          DateTime? consumedAt,
          double? amount,
          String? mealType}) =>
      NutritionLog(
        localId: localId ?? this.localId,
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        userId: userId.present ? userId.value : this.userId,
        productId: productId.present ? productId.value : this.productId,
        legacyBarcode:
            legacyBarcode.present ? legacyBarcode.value : this.legacyBarcode,
        consumedAt: consumedAt ?? this.consumedAt,
        amount: amount ?? this.amount,
        mealType: mealType ?? this.mealType,
      );
  NutritionLog copyWithCompanion(NutritionLogsCompanion data) {
    return NutritionLog(
      localId: data.localId.present ? data.localId.value : this.localId,
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      userId: data.userId.present ? data.userId.value : this.userId,
      productId: data.productId.present ? data.productId.value : this.productId,
      legacyBarcode: data.legacyBarcode.present
          ? data.legacyBarcode.value
          : this.legacyBarcode,
      consumedAt:
          data.consumedAt.present ? data.consumedAt.value : this.consumedAt,
      amount: data.amount.present ? data.amount.value : this.amount,
      mealType: data.mealType.present ? data.mealType.value : this.mealType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NutritionLog(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('userId: $userId, ')
          ..write('productId: $productId, ')
          ..write('legacyBarcode: $legacyBarcode, ')
          ..write('consumedAt: $consumedAt, ')
          ..write('amount: $amount, ')
          ..write('mealType: $mealType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(localId, id, createdAt, updatedAt, deletedAt,
      userId, productId, legacyBarcode, consumedAt, amount, mealType);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NutritionLog &&
          other.localId == this.localId &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.userId == this.userId &&
          other.productId == this.productId &&
          other.legacyBarcode == this.legacyBarcode &&
          other.consumedAt == this.consumedAt &&
          other.amount == this.amount &&
          other.mealType == this.mealType);
}

class NutritionLogsCompanion extends UpdateCompanion<NutritionLog> {
  final Value<int> localId;
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> userId;
  final Value<String?> productId;
  final Value<String?> legacyBarcode;
  final Value<DateTime> consumedAt;
  final Value<double> amount;
  final Value<String> mealType;
  const NutritionLogsCompanion({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.userId = const Value.absent(),
    this.productId = const Value.absent(),
    this.legacyBarcode = const Value.absent(),
    this.consumedAt = const Value.absent(),
    this.amount = const Value.absent(),
    this.mealType = const Value.absent(),
  });
  NutritionLogsCompanion.insert({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.userId = const Value.absent(),
    this.productId = const Value.absent(),
    this.legacyBarcode = const Value.absent(),
    required DateTime consumedAt,
    required double amount,
    this.mealType = const Value.absent(),
  })  : consumedAt = Value(consumedAt),
        amount = Value(amount);
  static Insertable<NutritionLog> custom({
    Expression<int>? localId,
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? userId,
    Expression<String>? productId,
    Expression<String>? legacyBarcode,
    Expression<DateTime>? consumedAt,
    Expression<double>? amount,
    Expression<String>? mealType,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (userId != null) 'user_id': userId,
      if (productId != null) 'product_id': productId,
      if (legacyBarcode != null) 'legacy_barcode': legacyBarcode,
      if (consumedAt != null) 'consumed_at': consumedAt,
      if (amount != null) 'amount': amount,
      if (mealType != null) 'meal_type': mealType,
    });
  }

  NutritionLogsCompanion copyWith(
      {Value<int>? localId,
      Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String?>? userId,
      Value<String?>? productId,
      Value<String?>? legacyBarcode,
      Value<DateTime>? consumedAt,
      Value<double>? amount,
      Value<String>? mealType}) {
    return NutritionLogsCompanion(
      localId: localId ?? this.localId,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      legacyBarcode: legacyBarcode ?? this.legacyBarcode,
      consumedAt: consumedAt ?? this.consumedAt,
      amount: amount ?? this.amount,
      mealType: mealType ?? this.mealType,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (legacyBarcode.present) {
      map['legacy_barcode'] = Variable<String>(legacyBarcode.value);
    }
    if (consumedAt.present) {
      map['consumed_at'] = Variable<DateTime>(consumedAt.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (mealType.present) {
      map['meal_type'] = Variable<String>(mealType.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NutritionLogsCompanion(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('userId: $userId, ')
          ..write('productId: $productId, ')
          ..write('legacyBarcode: $legacyBarcode, ')
          ..write('consumedAt: $consumedAt, ')
          ..write('amount: $amount, ')
          ..write('mealType: $mealType')
          ..write(')'))
        .toString();
  }
}

class $SupplementsTable extends Supplements
    with TableInfo<$SupplementsTable, Supplement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SupplementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
      'local_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _doseMeta = const VerificationMeta('dose');
  @override
  late final GeneratedColumn<double> dose = GeneratedColumn<double>(
      'dose', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dailyGoalMeta =
      const VerificationMeta('dailyGoal');
  @override
  late final GeneratedColumn<double> dailyGoal = GeneratedColumn<double>(
      'daily_goal', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _dailyLimitMeta =
      const VerificationMeta('dailyLimit');
  @override
  late final GeneratedColumn<double> dailyLimit = GeneratedColumn<double>(
      'daily_limit', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isBuiltinMeta =
      const VerificationMeta('isBuiltin');
  @override
  late final GeneratedColumn<bool> isBuiltin = GeneratedColumn<bool>(
      'is_builtin', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_builtin" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isTrackedMeta =
      const VerificationMeta('isTracked');
  @override
  late final GeneratedColumn<bool> isTracked = GeneratedColumn<bool>(
      'is_tracked', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_tracked" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        id,
        createdAt,
        updatedAt,
        deletedAt,
        code,
        name,
        dose,
        unit,
        dailyGoal,
        dailyLimit,
        notes,
        isBuiltin,
        isTracked
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'supplements';
  @override
  VerificationContext validateIntegrity(Insertable<Supplement> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('dose')) {
      context.handle(
          _doseMeta, dose.isAcceptableOrUnknown(data['dose']!, _doseMeta));
    } else if (isInserting) {
      context.missing(_doseMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('daily_goal')) {
      context.handle(_dailyGoalMeta,
          dailyGoal.isAcceptableOrUnknown(data['daily_goal']!, _dailyGoalMeta));
    }
    if (data.containsKey('daily_limit')) {
      context.handle(
          _dailyLimitMeta,
          dailyLimit.isAcceptableOrUnknown(
              data['daily_limit']!, _dailyLimitMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('is_builtin')) {
      context.handle(_isBuiltinMeta,
          isBuiltin.isAcceptableOrUnknown(data['is_builtin']!, _isBuiltinMeta));
    }
    if (data.containsKey('is_tracked')) {
      context.handle(_isTrackedMeta,
          isTracked.isAcceptableOrUnknown(data['is_tracked']!, _isTrackedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  Supplement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Supplement(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}local_id'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      dose: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}dose'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      dailyGoal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}daily_goal']),
      dailyLimit: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}daily_limit']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      isBuiltin: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_builtin'])!,
      isTracked: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_tracked'])!,
    );
  }

  @override
  $SupplementsTable createAlias(String alias) {
    return $SupplementsTable(attachedDatabase, alias);
  }
}

class Supplement extends DataClass implements Insertable<Supplement> {
  final int localId;
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? code;
  final String name;
  final double dose;
  final String unit;
  final double? dailyGoal;
  final double? dailyLimit;
  final String? notes;
  final bool isBuiltin;
  final bool isTracked;
  const Supplement(
      {required this.localId,
      required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      this.code,
      required this.name,
      required this.dose,
      required this.unit,
      this.dailyGoal,
      this.dailyLimit,
      this.notes,
      required this.isBuiltin,
      required this.isTracked});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || code != null) {
      map['code'] = Variable<String>(code);
    }
    map['name'] = Variable<String>(name);
    map['dose'] = Variable<double>(dose);
    map['unit'] = Variable<String>(unit);
    if (!nullToAbsent || dailyGoal != null) {
      map['daily_goal'] = Variable<double>(dailyGoal);
    }
    if (!nullToAbsent || dailyLimit != null) {
      map['daily_limit'] = Variable<double>(dailyLimit);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_builtin'] = Variable<bool>(isBuiltin);
    map['is_tracked'] = Variable<bool>(isTracked);
    return map;
  }

  SupplementsCompanion toCompanion(bool nullToAbsent) {
    return SupplementsCompanion(
      localId: Value(localId),
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      code: code == null && nullToAbsent ? const Value.absent() : Value(code),
      name: Value(name),
      dose: Value(dose),
      unit: Value(unit),
      dailyGoal: dailyGoal == null && nullToAbsent
          ? const Value.absent()
          : Value(dailyGoal),
      dailyLimit: dailyLimit == null && nullToAbsent
          ? const Value.absent()
          : Value(dailyLimit),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      isBuiltin: Value(isBuiltin),
      isTracked: Value(isTracked),
    );
  }

  factory Supplement.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Supplement(
      localId: serializer.fromJson<int>(json['localId']),
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      code: serializer.fromJson<String?>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      dose: serializer.fromJson<double>(json['dose']),
      unit: serializer.fromJson<String>(json['unit']),
      dailyGoal: serializer.fromJson<double?>(json['dailyGoal']),
      dailyLimit: serializer.fromJson<double?>(json['dailyLimit']),
      notes: serializer.fromJson<String?>(json['notes']),
      isBuiltin: serializer.fromJson<bool>(json['isBuiltin']),
      isTracked: serializer.fromJson<bool>(json['isTracked']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'code': serializer.toJson<String?>(code),
      'name': serializer.toJson<String>(name),
      'dose': serializer.toJson<double>(dose),
      'unit': serializer.toJson<String>(unit),
      'dailyGoal': serializer.toJson<double?>(dailyGoal),
      'dailyLimit': serializer.toJson<double?>(dailyLimit),
      'notes': serializer.toJson<String?>(notes),
      'isBuiltin': serializer.toJson<bool>(isBuiltin),
      'isTracked': serializer.toJson<bool>(isTracked),
    };
  }

  Supplement copyWith(
          {int? localId,
          String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          Value<String?> code = const Value.absent(),
          String? name,
          double? dose,
          String? unit,
          Value<double?> dailyGoal = const Value.absent(),
          Value<double?> dailyLimit = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          bool? isBuiltin,
          bool? isTracked}) =>
      Supplement(
        localId: localId ?? this.localId,
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        code: code.present ? code.value : this.code,
        name: name ?? this.name,
        dose: dose ?? this.dose,
        unit: unit ?? this.unit,
        dailyGoal: dailyGoal.present ? dailyGoal.value : this.dailyGoal,
        dailyLimit: dailyLimit.present ? dailyLimit.value : this.dailyLimit,
        notes: notes.present ? notes.value : this.notes,
        isBuiltin: isBuiltin ?? this.isBuiltin,
        isTracked: isTracked ?? this.isTracked,
      );
  Supplement copyWithCompanion(SupplementsCompanion data) {
    return Supplement(
      localId: data.localId.present ? data.localId.value : this.localId,
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      dose: data.dose.present ? data.dose.value : this.dose,
      unit: data.unit.present ? data.unit.value : this.unit,
      dailyGoal: data.dailyGoal.present ? data.dailyGoal.value : this.dailyGoal,
      dailyLimit:
          data.dailyLimit.present ? data.dailyLimit.value : this.dailyLimit,
      notes: data.notes.present ? data.notes.value : this.notes,
      isBuiltin: data.isBuiltin.present ? data.isBuiltin.value : this.isBuiltin,
      isTracked: data.isTracked.present ? data.isTracked.value : this.isTracked,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Supplement(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('dose: $dose, ')
          ..write('unit: $unit, ')
          ..write('dailyGoal: $dailyGoal, ')
          ..write('dailyLimit: $dailyLimit, ')
          ..write('notes: $notes, ')
          ..write('isBuiltin: $isBuiltin, ')
          ..write('isTracked: $isTracked')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      localId,
      id,
      createdAt,
      updatedAt,
      deletedAt,
      code,
      name,
      dose,
      unit,
      dailyGoal,
      dailyLimit,
      notes,
      isBuiltin,
      isTracked);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Supplement &&
          other.localId == this.localId &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.code == this.code &&
          other.name == this.name &&
          other.dose == this.dose &&
          other.unit == this.unit &&
          other.dailyGoal == this.dailyGoal &&
          other.dailyLimit == this.dailyLimit &&
          other.notes == this.notes &&
          other.isBuiltin == this.isBuiltin &&
          other.isTracked == this.isTracked);
}

class SupplementsCompanion extends UpdateCompanion<Supplement> {
  final Value<int> localId;
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> code;
  final Value<String> name;
  final Value<double> dose;
  final Value<String> unit;
  final Value<double?> dailyGoal;
  final Value<double?> dailyLimit;
  final Value<String?> notes;
  final Value<bool> isBuiltin;
  final Value<bool> isTracked;
  const SupplementsCompanion({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.dose = const Value.absent(),
    this.unit = const Value.absent(),
    this.dailyGoal = const Value.absent(),
    this.dailyLimit = const Value.absent(),
    this.notes = const Value.absent(),
    this.isBuiltin = const Value.absent(),
    this.isTracked = const Value.absent(),
  });
  SupplementsCompanion.insert({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.code = const Value.absent(),
    required String name,
    required double dose,
    required String unit,
    this.dailyGoal = const Value.absent(),
    this.dailyLimit = const Value.absent(),
    this.notes = const Value.absent(),
    this.isBuiltin = const Value.absent(),
    this.isTracked = const Value.absent(),
  })  : name = Value(name),
        dose = Value(dose),
        unit = Value(unit);
  static Insertable<Supplement> custom({
    Expression<int>? localId,
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? code,
    Expression<String>? name,
    Expression<double>? dose,
    Expression<String>? unit,
    Expression<double>? dailyGoal,
    Expression<double>? dailyLimit,
    Expression<String>? notes,
    Expression<bool>? isBuiltin,
    Expression<bool>? isTracked,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (dose != null) 'dose': dose,
      if (unit != null) 'unit': unit,
      if (dailyGoal != null) 'daily_goal': dailyGoal,
      if (dailyLimit != null) 'daily_limit': dailyLimit,
      if (notes != null) 'notes': notes,
      if (isBuiltin != null) 'is_builtin': isBuiltin,
      if (isTracked != null) 'is_tracked': isTracked,
    });
  }

  SupplementsCompanion copyWith(
      {Value<int>? localId,
      Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String?>? code,
      Value<String>? name,
      Value<double>? dose,
      Value<String>? unit,
      Value<double?>? dailyGoal,
      Value<double?>? dailyLimit,
      Value<String?>? notes,
      Value<bool>? isBuiltin,
      Value<bool>? isTracked}) {
    return SupplementsCompanion(
      localId: localId ?? this.localId,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      code: code ?? this.code,
      name: name ?? this.name,
      dose: dose ?? this.dose,
      unit: unit ?? this.unit,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      notes: notes ?? this.notes,
      isBuiltin: isBuiltin ?? this.isBuiltin,
      isTracked: isTracked ?? this.isTracked,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (dose.present) {
      map['dose'] = Variable<double>(dose.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (dailyGoal.present) {
      map['daily_goal'] = Variable<double>(dailyGoal.value);
    }
    if (dailyLimit.present) {
      map['daily_limit'] = Variable<double>(dailyLimit.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isBuiltin.present) {
      map['is_builtin'] = Variable<bool>(isBuiltin.value);
    }
    if (isTracked.present) {
      map['is_tracked'] = Variable<bool>(isTracked.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SupplementsCompanion(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('dose: $dose, ')
          ..write('unit: $unit, ')
          ..write('dailyGoal: $dailyGoal, ')
          ..write('dailyLimit: $dailyLimit, ')
          ..write('notes: $notes, ')
          ..write('isBuiltin: $isBuiltin, ')
          ..write('isTracked: $isTracked')
          ..write(')'))
        .toString();
  }
}

class $SupplementLogsTable extends SupplementLogs
    with TableInfo<$SupplementLogsTable, SupplementLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SupplementLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
      'local_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _supplementIdMeta =
      const VerificationMeta('supplementId');
  @override
  late final GeneratedColumn<String> supplementId = GeneratedColumn<String>(
      'supplement_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES supplements (id) ON DELETE CASCADE'));
  static const VerificationMeta _takenAtMeta =
      const VerificationMeta('takenAt');
  @override
  late final GeneratedColumn<DateTime> takenAt = GeneratedColumn<DateTime>(
      'taken_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _sourceNutritionLogIdMeta =
      const VerificationMeta('sourceNutritionLogId');
  @override
  late final GeneratedColumn<String> sourceNutritionLogId =
      GeneratedColumn<String>(
          'source_nutrition_log_id', aliasedName, true,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'REFERENCES nutrition_logs (id) ON DELETE SET NULL'));
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        id,
        createdAt,
        updatedAt,
        deletedAt,
        supplementId,
        takenAt,
        amount,
        sourceNutritionLogId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'supplement_logs';
  @override
  VerificationContext validateIntegrity(Insertable<SupplementLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('supplement_id')) {
      context.handle(
          _supplementIdMeta,
          supplementId.isAcceptableOrUnknown(
              data['supplement_id']!, _supplementIdMeta));
    } else if (isInserting) {
      context.missing(_supplementIdMeta);
    }
    if (data.containsKey('taken_at')) {
      context.handle(_takenAtMeta,
          takenAt.isAcceptableOrUnknown(data['taken_at']!, _takenAtMeta));
    } else if (isInserting) {
      context.missing(_takenAtMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('source_nutrition_log_id')) {
      context.handle(
          _sourceNutritionLogIdMeta,
          sourceNutritionLogId.isAcceptableOrUnknown(
              data['source_nutrition_log_id']!, _sourceNutritionLogIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  SupplementLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SupplementLog(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}local_id'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      supplementId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}supplement_id'])!,
      takenAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}taken_at'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      sourceNutritionLogId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source_nutrition_log_id']),
    );
  }

  @override
  $SupplementLogsTable createAlias(String alias) {
    return $SupplementLogsTable(attachedDatabase, alias);
  }
}

class SupplementLog extends DataClass implements Insertable<SupplementLog> {
  final int localId;
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String supplementId;
  final DateTime takenAt;
  final double amount;
  final String? sourceNutritionLogId;
  const SupplementLog(
      {required this.localId,
      required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.supplementId,
      required this.takenAt,
      required this.amount,
      this.sourceNutritionLogId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['supplement_id'] = Variable<String>(supplementId);
    map['taken_at'] = Variable<DateTime>(takenAt);
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || sourceNutritionLogId != null) {
      map['source_nutrition_log_id'] = Variable<String>(sourceNutritionLogId);
    }
    return map;
  }

  SupplementLogsCompanion toCompanion(bool nullToAbsent) {
    return SupplementLogsCompanion(
      localId: Value(localId),
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      supplementId: Value(supplementId),
      takenAt: Value(takenAt),
      amount: Value(amount),
      sourceNutritionLogId: sourceNutritionLogId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceNutritionLogId),
    );
  }

  factory SupplementLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SupplementLog(
      localId: serializer.fromJson<int>(json['localId']),
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      supplementId: serializer.fromJson<String>(json['supplementId']),
      takenAt: serializer.fromJson<DateTime>(json['takenAt']),
      amount: serializer.fromJson<double>(json['amount']),
      sourceNutritionLogId:
          serializer.fromJson<String?>(json['sourceNutritionLogId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'supplementId': serializer.toJson<String>(supplementId),
      'takenAt': serializer.toJson<DateTime>(takenAt),
      'amount': serializer.toJson<double>(amount),
      'sourceNutritionLogId': serializer.toJson<String?>(sourceNutritionLogId),
    };
  }

  SupplementLog copyWith(
          {int? localId,
          String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? supplementId,
          DateTime? takenAt,
          double? amount,
          Value<String?> sourceNutritionLogId = const Value.absent()}) =>
      SupplementLog(
        localId: localId ?? this.localId,
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        supplementId: supplementId ?? this.supplementId,
        takenAt: takenAt ?? this.takenAt,
        amount: amount ?? this.amount,
        sourceNutritionLogId: sourceNutritionLogId.present
            ? sourceNutritionLogId.value
            : this.sourceNutritionLogId,
      );
  SupplementLog copyWithCompanion(SupplementLogsCompanion data) {
    return SupplementLog(
      localId: data.localId.present ? data.localId.value : this.localId,
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      supplementId: data.supplementId.present
          ? data.supplementId.value
          : this.supplementId,
      takenAt: data.takenAt.present ? data.takenAt.value : this.takenAt,
      amount: data.amount.present ? data.amount.value : this.amount,
      sourceNutritionLogId: data.sourceNutritionLogId.present
          ? data.sourceNutritionLogId.value
          : this.sourceNutritionLogId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SupplementLog(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('supplementId: $supplementId, ')
          ..write('takenAt: $takenAt, ')
          ..write('amount: $amount, ')
          ..write('sourceNutritionLogId: $sourceNutritionLogId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(localId, id, createdAt, updatedAt, deletedAt,
      supplementId, takenAt, amount, sourceNutritionLogId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SupplementLog &&
          other.localId == this.localId &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.supplementId == this.supplementId &&
          other.takenAt == this.takenAt &&
          other.amount == this.amount &&
          other.sourceNutritionLogId == this.sourceNutritionLogId);
}

class SupplementLogsCompanion extends UpdateCompanion<SupplementLog> {
  final Value<int> localId;
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> supplementId;
  final Value<DateTime> takenAt;
  final Value<double> amount;
  final Value<String?> sourceNutritionLogId;
  const SupplementLogsCompanion({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.supplementId = const Value.absent(),
    this.takenAt = const Value.absent(),
    this.amount = const Value.absent(),
    this.sourceNutritionLogId = const Value.absent(),
  });
  SupplementLogsCompanion.insert({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String supplementId,
    required DateTime takenAt,
    required double amount,
    this.sourceNutritionLogId = const Value.absent(),
  })  : supplementId = Value(supplementId),
        takenAt = Value(takenAt),
        amount = Value(amount);
  static Insertable<SupplementLog> custom({
    Expression<int>? localId,
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? supplementId,
    Expression<DateTime>? takenAt,
    Expression<double>? amount,
    Expression<String>? sourceNutritionLogId,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (supplementId != null) 'supplement_id': supplementId,
      if (takenAt != null) 'taken_at': takenAt,
      if (amount != null) 'amount': amount,
      if (sourceNutritionLogId != null)
        'source_nutrition_log_id': sourceNutritionLogId,
    });
  }

  SupplementLogsCompanion copyWith(
      {Value<int>? localId,
      Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? supplementId,
      Value<DateTime>? takenAt,
      Value<double>? amount,
      Value<String?>? sourceNutritionLogId}) {
    return SupplementLogsCompanion(
      localId: localId ?? this.localId,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      supplementId: supplementId ?? this.supplementId,
      takenAt: takenAt ?? this.takenAt,
      amount: amount ?? this.amount,
      sourceNutritionLogId: sourceNutritionLogId ?? this.sourceNutritionLogId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (supplementId.present) {
      map['supplement_id'] = Variable<String>(supplementId.value);
    }
    if (takenAt.present) {
      map['taken_at'] = Variable<DateTime>(takenAt.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (sourceNutritionLogId.present) {
      map['source_nutrition_log_id'] =
          Variable<String>(sourceNutritionLogId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SupplementLogsCompanion(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('supplementId: $supplementId, ')
          ..write('takenAt: $takenAt, ')
          ..write('amount: $amount, ')
          ..write('sourceNutritionLogId: $sourceNutritionLogId')
          ..write(')'))
        .toString();
  }
}

class $FluidLogsTable extends FluidLogs
    with TableInfo<$FluidLogsTable, FluidLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FluidLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
      'local_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _consumedAtMeta =
      const VerificationMeta('consumedAt');
  @override
  late final GeneratedColumn<DateTime> consumedAt = GeneratedColumn<DateTime>(
      'consumed_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _amountMlMeta =
      const VerificationMeta('amountMl');
  @override
  late final GeneratedColumn<int> amountMl = GeneratedColumn<int>(
      'amount_ml', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kcalMeta = const VerificationMeta('kcal');
  @override
  late final GeneratedColumn<int> kcal = GeneratedColumn<int>(
      'kcal', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _sugarPer100mlMeta =
      const VerificationMeta('sugarPer100ml');
  @override
  late final GeneratedColumn<double> sugarPer100ml = GeneratedColumn<double>(
      'sugar_per100ml', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _caffeinePer100mlMeta =
      const VerificationMeta('caffeinePer100ml');
  @override
  late final GeneratedColumn<double> caffeinePer100ml = GeneratedColumn<double>(
      'caffeine_per100ml', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _linkedNutritionLogIdMeta =
      const VerificationMeta('linkedNutritionLogId');
  @override
  late final GeneratedColumn<String> linkedNutritionLogId =
      GeneratedColumn<String>(
          'linked_nutrition_log_id', aliasedName, true,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'REFERENCES nutrition_logs (id) ON DELETE CASCADE'));
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        id,
        createdAt,
        updatedAt,
        deletedAt,
        consumedAt,
        amountMl,
        name,
        kcal,
        sugarPer100ml,
        caffeinePer100ml,
        linkedNutritionLogId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fluid_logs';
  @override
  VerificationContext validateIntegrity(Insertable<FluidLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('consumed_at')) {
      context.handle(
          _consumedAtMeta,
          consumedAt.isAcceptableOrUnknown(
              data['consumed_at']!, _consumedAtMeta));
    } else if (isInserting) {
      context.missing(_consumedAtMeta);
    }
    if (data.containsKey('amount_ml')) {
      context.handle(_amountMlMeta,
          amountMl.isAcceptableOrUnknown(data['amount_ml']!, _amountMlMeta));
    } else if (isInserting) {
      context.missing(_amountMlMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kcal')) {
      context.handle(
          _kcalMeta, kcal.isAcceptableOrUnknown(data['kcal']!, _kcalMeta));
    }
    if (data.containsKey('sugar_per100ml')) {
      context.handle(
          _sugarPer100mlMeta,
          sugarPer100ml.isAcceptableOrUnknown(
              data['sugar_per100ml']!, _sugarPer100mlMeta));
    }
    if (data.containsKey('caffeine_per100ml')) {
      context.handle(
          _caffeinePer100mlMeta,
          caffeinePer100ml.isAcceptableOrUnknown(
              data['caffeine_per100ml']!, _caffeinePer100mlMeta));
    }
    if (data.containsKey('linked_nutrition_log_id')) {
      context.handle(
          _linkedNutritionLogIdMeta,
          linkedNutritionLogId.isAcceptableOrUnknown(
              data['linked_nutrition_log_id']!, _linkedNutritionLogIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  FluidLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FluidLog(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}local_id'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      consumedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}consumed_at'])!,
      amountMl: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount_ml'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      kcal: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}kcal']),
      sugarPer100ml: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}sugar_per100ml']),
      caffeinePer100ml: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}caffeine_per100ml']),
      linkedNutritionLogId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}linked_nutrition_log_id']),
    );
  }

  @override
  $FluidLogsTable createAlias(String alias) {
    return $FluidLogsTable(attachedDatabase, alias);
  }
}

class FluidLog extends DataClass implements Insertable<FluidLog> {
  final int localId;
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime consumedAt;
  final int amountMl;
  final String name;
  final int? kcal;
  final double? sugarPer100ml;
  final double? caffeinePer100ml;
  final String? linkedNutritionLogId;
  const FluidLog(
      {required this.localId,
      required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.consumedAt,
      required this.amountMl,
      required this.name,
      this.kcal,
      this.sugarPer100ml,
      this.caffeinePer100ml,
      this.linkedNutritionLogId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['consumed_at'] = Variable<DateTime>(consumedAt);
    map['amount_ml'] = Variable<int>(amountMl);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || kcal != null) {
      map['kcal'] = Variable<int>(kcal);
    }
    if (!nullToAbsent || sugarPer100ml != null) {
      map['sugar_per100ml'] = Variable<double>(sugarPer100ml);
    }
    if (!nullToAbsent || caffeinePer100ml != null) {
      map['caffeine_per100ml'] = Variable<double>(caffeinePer100ml);
    }
    if (!nullToAbsent || linkedNutritionLogId != null) {
      map['linked_nutrition_log_id'] = Variable<String>(linkedNutritionLogId);
    }
    return map;
  }

  FluidLogsCompanion toCompanion(bool nullToAbsent) {
    return FluidLogsCompanion(
      localId: Value(localId),
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      consumedAt: Value(consumedAt),
      amountMl: Value(amountMl),
      name: Value(name),
      kcal: kcal == null && nullToAbsent ? const Value.absent() : Value(kcal),
      sugarPer100ml: sugarPer100ml == null && nullToAbsent
          ? const Value.absent()
          : Value(sugarPer100ml),
      caffeinePer100ml: caffeinePer100ml == null && nullToAbsent
          ? const Value.absent()
          : Value(caffeinePer100ml),
      linkedNutritionLogId: linkedNutritionLogId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedNutritionLogId),
    );
  }

  factory FluidLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FluidLog(
      localId: serializer.fromJson<int>(json['localId']),
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      consumedAt: serializer.fromJson<DateTime>(json['consumedAt']),
      amountMl: serializer.fromJson<int>(json['amountMl']),
      name: serializer.fromJson<String>(json['name']),
      kcal: serializer.fromJson<int?>(json['kcal']),
      sugarPer100ml: serializer.fromJson<double?>(json['sugarPer100ml']),
      caffeinePer100ml: serializer.fromJson<double?>(json['caffeinePer100ml']),
      linkedNutritionLogId:
          serializer.fromJson<String?>(json['linkedNutritionLogId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'consumedAt': serializer.toJson<DateTime>(consumedAt),
      'amountMl': serializer.toJson<int>(amountMl),
      'name': serializer.toJson<String>(name),
      'kcal': serializer.toJson<int?>(kcal),
      'sugarPer100ml': serializer.toJson<double?>(sugarPer100ml),
      'caffeinePer100ml': serializer.toJson<double?>(caffeinePer100ml),
      'linkedNutritionLogId': serializer.toJson<String?>(linkedNutritionLogId),
    };
  }

  FluidLog copyWith(
          {int? localId,
          String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          DateTime? consumedAt,
          int? amountMl,
          String? name,
          Value<int?> kcal = const Value.absent(),
          Value<double?> sugarPer100ml = const Value.absent(),
          Value<double?> caffeinePer100ml = const Value.absent(),
          Value<String?> linkedNutritionLogId = const Value.absent()}) =>
      FluidLog(
        localId: localId ?? this.localId,
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        consumedAt: consumedAt ?? this.consumedAt,
        amountMl: amountMl ?? this.amountMl,
        name: name ?? this.name,
        kcal: kcal.present ? kcal.value : this.kcal,
        sugarPer100ml:
            sugarPer100ml.present ? sugarPer100ml.value : this.sugarPer100ml,
        caffeinePer100ml: caffeinePer100ml.present
            ? caffeinePer100ml.value
            : this.caffeinePer100ml,
        linkedNutritionLogId: linkedNutritionLogId.present
            ? linkedNutritionLogId.value
            : this.linkedNutritionLogId,
      );
  FluidLog copyWithCompanion(FluidLogsCompanion data) {
    return FluidLog(
      localId: data.localId.present ? data.localId.value : this.localId,
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      consumedAt:
          data.consumedAt.present ? data.consumedAt.value : this.consumedAt,
      amountMl: data.amountMl.present ? data.amountMl.value : this.amountMl,
      name: data.name.present ? data.name.value : this.name,
      kcal: data.kcal.present ? data.kcal.value : this.kcal,
      sugarPer100ml: data.sugarPer100ml.present
          ? data.sugarPer100ml.value
          : this.sugarPer100ml,
      caffeinePer100ml: data.caffeinePer100ml.present
          ? data.caffeinePer100ml.value
          : this.caffeinePer100ml,
      linkedNutritionLogId: data.linkedNutritionLogId.present
          ? data.linkedNutritionLogId.value
          : this.linkedNutritionLogId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FluidLog(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('consumedAt: $consumedAt, ')
          ..write('amountMl: $amountMl, ')
          ..write('name: $name, ')
          ..write('kcal: $kcal, ')
          ..write('sugarPer100ml: $sugarPer100ml, ')
          ..write('caffeinePer100ml: $caffeinePer100ml, ')
          ..write('linkedNutritionLogId: $linkedNutritionLogId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      localId,
      id,
      createdAt,
      updatedAt,
      deletedAt,
      consumedAt,
      amountMl,
      name,
      kcal,
      sugarPer100ml,
      caffeinePer100ml,
      linkedNutritionLogId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FluidLog &&
          other.localId == this.localId &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.consumedAt == this.consumedAt &&
          other.amountMl == this.amountMl &&
          other.name == this.name &&
          other.kcal == this.kcal &&
          other.sugarPer100ml == this.sugarPer100ml &&
          other.caffeinePer100ml == this.caffeinePer100ml &&
          other.linkedNutritionLogId == this.linkedNutritionLogId);
}

class FluidLogsCompanion extends UpdateCompanion<FluidLog> {
  final Value<int> localId;
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> consumedAt;
  final Value<int> amountMl;
  final Value<String> name;
  final Value<int?> kcal;
  final Value<double?> sugarPer100ml;
  final Value<double?> caffeinePer100ml;
  final Value<String?> linkedNutritionLogId;
  const FluidLogsCompanion({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.consumedAt = const Value.absent(),
    this.amountMl = const Value.absent(),
    this.name = const Value.absent(),
    this.kcal = const Value.absent(),
    this.sugarPer100ml = const Value.absent(),
    this.caffeinePer100ml = const Value.absent(),
    this.linkedNutritionLogId = const Value.absent(),
  });
  FluidLogsCompanion.insert({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required DateTime consumedAt,
    required int amountMl,
    required String name,
    this.kcal = const Value.absent(),
    this.sugarPer100ml = const Value.absent(),
    this.caffeinePer100ml = const Value.absent(),
    this.linkedNutritionLogId = const Value.absent(),
  })  : consumedAt = Value(consumedAt),
        amountMl = Value(amountMl),
        name = Value(name);
  static Insertable<FluidLog> custom({
    Expression<int>? localId,
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? consumedAt,
    Expression<int>? amountMl,
    Expression<String>? name,
    Expression<int>? kcal,
    Expression<double>? sugarPer100ml,
    Expression<double>? caffeinePer100ml,
    Expression<String>? linkedNutritionLogId,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (consumedAt != null) 'consumed_at': consumedAt,
      if (amountMl != null) 'amount_ml': amountMl,
      if (name != null) 'name': name,
      if (kcal != null) 'kcal': kcal,
      if (sugarPer100ml != null) 'sugar_per100ml': sugarPer100ml,
      if (caffeinePer100ml != null) 'caffeine_per100ml': caffeinePer100ml,
      if (linkedNutritionLogId != null)
        'linked_nutrition_log_id': linkedNutritionLogId,
    });
  }

  FluidLogsCompanion copyWith(
      {Value<int>? localId,
      Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<DateTime>? consumedAt,
      Value<int>? amountMl,
      Value<String>? name,
      Value<int?>? kcal,
      Value<double?>? sugarPer100ml,
      Value<double?>? caffeinePer100ml,
      Value<String?>? linkedNutritionLogId}) {
    return FluidLogsCompanion(
      localId: localId ?? this.localId,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      consumedAt: consumedAt ?? this.consumedAt,
      amountMl: amountMl ?? this.amountMl,
      name: name ?? this.name,
      kcal: kcal ?? this.kcal,
      sugarPer100ml: sugarPer100ml ?? this.sugarPer100ml,
      caffeinePer100ml: caffeinePer100ml ?? this.caffeinePer100ml,
      linkedNutritionLogId: linkedNutritionLogId ?? this.linkedNutritionLogId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (consumedAt.present) {
      map['consumed_at'] = Variable<DateTime>(consumedAt.value);
    }
    if (amountMl.present) {
      map['amount_ml'] = Variable<int>(amountMl.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kcal.present) {
      map['kcal'] = Variable<int>(kcal.value);
    }
    if (sugarPer100ml.present) {
      map['sugar_per100ml'] = Variable<double>(sugarPer100ml.value);
    }
    if (caffeinePer100ml.present) {
      map['caffeine_per100ml'] = Variable<double>(caffeinePer100ml.value);
    }
    if (linkedNutritionLogId.present) {
      map['linked_nutrition_log_id'] =
          Variable<String>(linkedNutritionLogId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FluidLogsCompanion(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('consumedAt: $consumedAt, ')
          ..write('amountMl: $amountMl, ')
          ..write('name: $name, ')
          ..write('kcal: $kcal, ')
          ..write('sugarPer100ml: $sugarPer100ml, ')
          ..write('caffeinePer100ml: $caffeinePer100ml, ')
          ..write('linkedNutritionLogId: $linkedNutritionLogId')
          ..write(')'))
        .toString();
  }
}

class $MeasurementsTable extends Measurements
    with TableInfo<$MeasurementsTable, Measurement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeasurementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
      'local_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
      'value', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _legacySessionIdMeta =
      const VerificationMeta('legacySessionId');
  @override
  late final GeneratedColumn<int> legacySessionId = GeneratedColumn<int>(
      'legacy_session_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        id,
        createdAt,
        updatedAt,
        deletedAt,
        userId,
        type,
        value,
        unit,
        date,
        legacySessionId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'measurements';
  @override
  VerificationContext validateIntegrity(Insertable<Measurement> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('legacy_session_id')) {
      context.handle(
          _legacySessionIdMeta,
          legacySessionId.isAcceptableOrUnknown(
              data['legacy_session_id']!, _legacySessionIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  Measurement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Measurement(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}local_id'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}value'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      legacySessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}legacy_session_id']),
    );
  }

  @override
  $MeasurementsTable createAlias(String alias) {
    return $MeasurementsTable(attachedDatabase, alias);
  }
}

class Measurement extends DataClass implements Insertable<Measurement> {
  final int localId;
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? userId;
  final String type;
  final double value;
  final String unit;
  final DateTime date;
  final int? legacySessionId;
  const Measurement(
      {required this.localId,
      required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      this.userId,
      required this.type,
      required this.value,
      required this.unit,
      required this.date,
      this.legacySessionId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['type'] = Variable<String>(type);
    map['value'] = Variable<double>(value);
    map['unit'] = Variable<String>(unit);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || legacySessionId != null) {
      map['legacy_session_id'] = Variable<int>(legacySessionId);
    }
    return map;
  }

  MeasurementsCompanion toCompanion(bool nullToAbsent) {
    return MeasurementsCompanion(
      localId: Value(localId),
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      type: Value(type),
      value: Value(value),
      unit: Value(unit),
      date: Value(date),
      legacySessionId: legacySessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(legacySessionId),
    );
  }

  factory Measurement.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Measurement(
      localId: serializer.fromJson<int>(json['localId']),
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      userId: serializer.fromJson<String?>(json['userId']),
      type: serializer.fromJson<String>(json['type']),
      value: serializer.fromJson<double>(json['value']),
      unit: serializer.fromJson<String>(json['unit']),
      date: serializer.fromJson<DateTime>(json['date']),
      legacySessionId: serializer.fromJson<int?>(json['legacySessionId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'userId': serializer.toJson<String?>(userId),
      'type': serializer.toJson<String>(type),
      'value': serializer.toJson<double>(value),
      'unit': serializer.toJson<String>(unit),
      'date': serializer.toJson<DateTime>(date),
      'legacySessionId': serializer.toJson<int?>(legacySessionId),
    };
  }

  Measurement copyWith(
          {int? localId,
          String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          Value<String?> userId = const Value.absent(),
          String? type,
          double? value,
          String? unit,
          DateTime? date,
          Value<int?> legacySessionId = const Value.absent()}) =>
      Measurement(
        localId: localId ?? this.localId,
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        userId: userId.present ? userId.value : this.userId,
        type: type ?? this.type,
        value: value ?? this.value,
        unit: unit ?? this.unit,
        date: date ?? this.date,
        legacySessionId: legacySessionId.present
            ? legacySessionId.value
            : this.legacySessionId,
      );
  Measurement copyWithCompanion(MeasurementsCompanion data) {
    return Measurement(
      localId: data.localId.present ? data.localId.value : this.localId,
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      userId: data.userId.present ? data.userId.value : this.userId,
      type: data.type.present ? data.type.value : this.type,
      value: data.value.present ? data.value.value : this.value,
      unit: data.unit.present ? data.unit.value : this.unit,
      date: data.date.present ? data.date.value : this.date,
      legacySessionId: data.legacySessionId.present
          ? data.legacySessionId.value
          : this.legacySessionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Measurement(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('userId: $userId, ')
          ..write('type: $type, ')
          ..write('value: $value, ')
          ..write('unit: $unit, ')
          ..write('date: $date, ')
          ..write('legacySessionId: $legacySessionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(localId, id, createdAt, updatedAt, deletedAt,
      userId, type, value, unit, date, legacySessionId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Measurement &&
          other.localId == this.localId &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.userId == this.userId &&
          other.type == this.type &&
          other.value == this.value &&
          other.unit == this.unit &&
          other.date == this.date &&
          other.legacySessionId == this.legacySessionId);
}

class MeasurementsCompanion extends UpdateCompanion<Measurement> {
  final Value<int> localId;
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> userId;
  final Value<String> type;
  final Value<double> value;
  final Value<String> unit;
  final Value<DateTime> date;
  final Value<int?> legacySessionId;
  const MeasurementsCompanion({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.userId = const Value.absent(),
    this.type = const Value.absent(),
    this.value = const Value.absent(),
    this.unit = const Value.absent(),
    this.date = const Value.absent(),
    this.legacySessionId = const Value.absent(),
  });
  MeasurementsCompanion.insert({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.userId = const Value.absent(),
    required String type,
    required double value,
    required String unit,
    required DateTime date,
    this.legacySessionId = const Value.absent(),
  })  : type = Value(type),
        value = Value(value),
        unit = Value(unit),
        date = Value(date);
  static Insertable<Measurement> custom({
    Expression<int>? localId,
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? userId,
    Expression<String>? type,
    Expression<double>? value,
    Expression<String>? unit,
    Expression<DateTime>? date,
    Expression<int>? legacySessionId,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (userId != null) 'user_id': userId,
      if (type != null) 'type': type,
      if (value != null) 'value': value,
      if (unit != null) 'unit': unit,
      if (date != null) 'date': date,
      if (legacySessionId != null) 'legacy_session_id': legacySessionId,
    });
  }

  MeasurementsCompanion copyWith(
      {Value<int>? localId,
      Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String?>? userId,
      Value<String>? type,
      Value<double>? value,
      Value<String>? unit,
      Value<DateTime>? date,
      Value<int?>? legacySessionId}) {
    return MeasurementsCompanion(
      localId: localId ?? this.localId,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      date: date ?? this.date,
      legacySessionId: legacySessionId ?? this.legacySessionId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (legacySessionId.present) {
      map['legacy_session_id'] = Variable<int>(legacySessionId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeasurementsCompanion(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('userId: $userId, ')
          ..write('type: $type, ')
          ..write('value: $value, ')
          ..write('unit: $unit, ')
          ..write('date: $date, ')
          ..write('legacySessionId: $legacySessionId')
          ..write(')'))
        .toString();
  }
}

class $PostsTable extends Posts with TableInfo<$PostsTable, Post> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PostsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
      'local_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _referenceIdMeta =
      const VerificationMeta('referenceId');
  @override
  late final GeneratedColumn<String> referenceId = GeneratedColumn<String>(
      'reference_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _metadataMeta =
      const VerificationMeta('metadata');
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
      'metadata', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        id,
        createdAt,
        updatedAt,
        deletedAt,
        userId,
        type,
        referenceId,
        metadata,
        content
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'posts';
  @override
  VerificationContext validateIntegrity(Insertable<Post> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('reference_id')) {
      context.handle(
          _referenceIdMeta,
          referenceId.isAcceptableOrUnknown(
              data['reference_id']!, _referenceIdMeta));
    }
    if (data.containsKey('metadata')) {
      context.handle(_metadataMeta,
          metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta));
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  Post map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Post(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}local_id'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      referenceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reference_id']),
      metadata: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata']),
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content']),
    );
  }

  @override
  $PostsTable createAlias(String alias) {
    return $PostsTable(attachedDatabase, alias);
  }
}

class Post extends DataClass implements Insertable<Post> {
  final int localId;
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String userId;
  final String type;
  final String? referenceId;
  final String? metadata;
  final String? content;
  const Post(
      {required this.localId,
      required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.userId,
      required this.type,
      this.referenceId,
      this.metadata,
      this.content});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['user_id'] = Variable<String>(userId);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || referenceId != null) {
      map['reference_id'] = Variable<String>(referenceId);
    }
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    return map;
  }

  PostsCompanion toCompanion(bool nullToAbsent) {
    return PostsCompanion(
      localId: Value(localId),
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      userId: Value(userId),
      type: Value(type),
      referenceId: referenceId == null && nullToAbsent
          ? const Value.absent()
          : Value(referenceId),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
    );
  }

  factory Post.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Post(
      localId: serializer.fromJson<int>(json['localId']),
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      userId: serializer.fromJson<String>(json['userId']),
      type: serializer.fromJson<String>(json['type']),
      referenceId: serializer.fromJson<String?>(json['referenceId']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      content: serializer.fromJson<String?>(json['content']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'userId': serializer.toJson<String>(userId),
      'type': serializer.toJson<String>(type),
      'referenceId': serializer.toJson<String?>(referenceId),
      'metadata': serializer.toJson<String?>(metadata),
      'content': serializer.toJson<String?>(content),
    };
  }

  Post copyWith(
          {int? localId,
          String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? userId,
          String? type,
          Value<String?> referenceId = const Value.absent(),
          Value<String?> metadata = const Value.absent(),
          Value<String?> content = const Value.absent()}) =>
      Post(
        localId: localId ?? this.localId,
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        userId: userId ?? this.userId,
        type: type ?? this.type,
        referenceId: referenceId.present ? referenceId.value : this.referenceId,
        metadata: metadata.present ? metadata.value : this.metadata,
        content: content.present ? content.value : this.content,
      );
  Post copyWithCompanion(PostsCompanion data) {
    return Post(
      localId: data.localId.present ? data.localId.value : this.localId,
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      userId: data.userId.present ? data.userId.value : this.userId,
      type: data.type.present ? data.type.value : this.type,
      referenceId:
          data.referenceId.present ? data.referenceId.value : this.referenceId,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      content: data.content.present ? data.content.value : this.content,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Post(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('userId: $userId, ')
          ..write('type: $type, ')
          ..write('referenceId: $referenceId, ')
          ..write('metadata: $metadata, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(localId, id, createdAt, updatedAt, deletedAt,
      userId, type, referenceId, metadata, content);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Post &&
          other.localId == this.localId &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.userId == this.userId &&
          other.type == this.type &&
          other.referenceId == this.referenceId &&
          other.metadata == this.metadata &&
          other.content == this.content);
}

class PostsCompanion extends UpdateCompanion<Post> {
  final Value<int> localId;
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> userId;
  final Value<String> type;
  final Value<String?> referenceId;
  final Value<String?> metadata;
  final Value<String?> content;
  const PostsCompanion({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.userId = const Value.absent(),
    this.type = const Value.absent(),
    this.referenceId = const Value.absent(),
    this.metadata = const Value.absent(),
    this.content = const Value.absent(),
  });
  PostsCompanion.insert({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String userId,
    required String type,
    this.referenceId = const Value.absent(),
    this.metadata = const Value.absent(),
    this.content = const Value.absent(),
  })  : userId = Value(userId),
        type = Value(type);
  static Insertable<Post> custom({
    Expression<int>? localId,
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? userId,
    Expression<String>? type,
    Expression<String>? referenceId,
    Expression<String>? metadata,
    Expression<String>? content,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (userId != null) 'user_id': userId,
      if (type != null) 'type': type,
      if (referenceId != null) 'reference_id': referenceId,
      if (metadata != null) 'metadata': metadata,
      if (content != null) 'content': content,
    });
  }

  PostsCompanion copyWith(
      {Value<int>? localId,
      Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? userId,
      Value<String>? type,
      Value<String?>? referenceId,
      Value<String?>? metadata,
      Value<String?>? content}) {
    return PostsCompanion(
      localId: localId ?? this.localId,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      referenceId: referenceId ?? this.referenceId,
      metadata: metadata ?? this.metadata,
      content: content ?? this.content,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (referenceId.present) {
      map['reference_id'] = Variable<String>(referenceId.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PostsCompanion(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('userId: $userId, ')
          ..write('type: $type, ')
          ..write('referenceId: $referenceId, ')
          ..write('metadata: $metadata, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }
}

class $SocialInteractionsTable extends SocialInteractions
    with TableInfo<$SocialInteractionsTable, SocialInteraction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SocialInteractionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
      'local_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _postIdMeta = const VerificationMeta('postId');
  @override
  late final GeneratedColumn<String> postId = GeneratedColumn<String>(
      'post_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES posts (id) ON DELETE CASCADE'));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        id,
        createdAt,
        updatedAt,
        deletedAt,
        postId,
        userId,
        type,
        content
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'social_interactions';
  @override
  VerificationContext validateIntegrity(Insertable<SocialInteraction> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('post_id')) {
      context.handle(_postIdMeta,
          postId.isAcceptableOrUnknown(data['post_id']!, _postIdMeta));
    } else if (isInserting) {
      context.missing(_postIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  SocialInteraction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SocialInteraction(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}local_id'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      postId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}post_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content']),
    );
  }

  @override
  $SocialInteractionsTable createAlias(String alias) {
    return $SocialInteractionsTable(attachedDatabase, alias);
  }
}

class SocialInteraction extends DataClass
    implements Insertable<SocialInteraction> {
  final int localId;
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String postId;
  final String userId;
  final String type;
  final String? content;
  const SocialInteraction(
      {required this.localId,
      required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.postId,
      required this.userId,
      required this.type,
      this.content});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['post_id'] = Variable<String>(postId);
    map['user_id'] = Variable<String>(userId);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    return map;
  }

  SocialInteractionsCompanion toCompanion(bool nullToAbsent) {
    return SocialInteractionsCompanion(
      localId: Value(localId),
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      postId: Value(postId),
      userId: Value(userId),
      type: Value(type),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
    );
  }

  factory SocialInteraction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SocialInteraction(
      localId: serializer.fromJson<int>(json['localId']),
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      postId: serializer.fromJson<String>(json['postId']),
      userId: serializer.fromJson<String>(json['userId']),
      type: serializer.fromJson<String>(json['type']),
      content: serializer.fromJson<String?>(json['content']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'postId': serializer.toJson<String>(postId),
      'userId': serializer.toJson<String>(userId),
      'type': serializer.toJson<String>(type),
      'content': serializer.toJson<String?>(content),
    };
  }

  SocialInteraction copyWith(
          {int? localId,
          String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? postId,
          String? userId,
          String? type,
          Value<String?> content = const Value.absent()}) =>
      SocialInteraction(
        localId: localId ?? this.localId,
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        postId: postId ?? this.postId,
        userId: userId ?? this.userId,
        type: type ?? this.type,
        content: content.present ? content.value : this.content,
      );
  SocialInteraction copyWithCompanion(SocialInteractionsCompanion data) {
    return SocialInteraction(
      localId: data.localId.present ? data.localId.value : this.localId,
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      postId: data.postId.present ? data.postId.value : this.postId,
      userId: data.userId.present ? data.userId.value : this.userId,
      type: data.type.present ? data.type.value : this.type,
      content: data.content.present ? data.content.value : this.content,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SocialInteraction(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('postId: $postId, ')
          ..write('userId: $userId, ')
          ..write('type: $type, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(localId, id, createdAt, updatedAt, deletedAt,
      postId, userId, type, content);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SocialInteraction &&
          other.localId == this.localId &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.postId == this.postId &&
          other.userId == this.userId &&
          other.type == this.type &&
          other.content == this.content);
}

class SocialInteractionsCompanion extends UpdateCompanion<SocialInteraction> {
  final Value<int> localId;
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> postId;
  final Value<String> userId;
  final Value<String> type;
  final Value<String?> content;
  const SocialInteractionsCompanion({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.postId = const Value.absent(),
    this.userId = const Value.absent(),
    this.type = const Value.absent(),
    this.content = const Value.absent(),
  });
  SocialInteractionsCompanion.insert({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String postId,
    required String userId,
    required String type,
    this.content = const Value.absent(),
  })  : postId = Value(postId),
        userId = Value(userId),
        type = Value(type);
  static Insertable<SocialInteraction> custom({
    Expression<int>? localId,
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? postId,
    Expression<String>? userId,
    Expression<String>? type,
    Expression<String>? content,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (postId != null) 'post_id': postId,
      if (userId != null) 'user_id': userId,
      if (type != null) 'type': type,
      if (content != null) 'content': content,
    });
  }

  SocialInteractionsCompanion copyWith(
      {Value<int>? localId,
      Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? postId,
      Value<String>? userId,
      Value<String>? type,
      Value<String?>? content}) {
    return SocialInteractionsCompanion(
      localId: localId ?? this.localId,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      content: content ?? this.content,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (postId.present) {
      map['post_id'] = Variable<String>(postId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SocialInteractionsCompanion(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('postId: $postId, ')
          ..write('userId: $userId, ')
          ..write('type: $type, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }
}

class $MealsTable extends Meals with TableInfo<$MealsTable, Meal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
      'local_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [localId, id, createdAt, updatedAt, deletedAt, userId, name, notes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meals';
  @override
  VerificationContext validateIntegrity(Insertable<Meal> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  Meal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Meal(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}local_id'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
    );
  }

  @override
  $MealsTable createAlias(String alias) {
    return $MealsTable(attachedDatabase, alias);
  }
}

class Meal extends DataClass implements Insertable<Meal> {
  final int localId;
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? userId;
  final String name;
  final String? notes;
  const Meal(
      {required this.localId,
      required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      this.userId,
      required this.name,
      this.notes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  MealsCompanion toCompanion(bool nullToAbsent) {
    return MealsCompanion(
      localId: Value(localId),
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      name: Value(name),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
    );
  }

  factory Meal.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Meal(
      localId: serializer.fromJson<int>(json['localId']),
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      userId: serializer.fromJson<String?>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'userId': serializer.toJson<String?>(userId),
      'name': serializer.toJson<String>(name),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  Meal copyWith(
          {int? localId,
          String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          Value<String?> userId = const Value.absent(),
          String? name,
          Value<String?> notes = const Value.absent()}) =>
      Meal(
        localId: localId ?? this.localId,
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        userId: userId.present ? userId.value : this.userId,
        name: name ?? this.name,
        notes: notes.present ? notes.value : this.notes,
      );
  Meal copyWithCompanion(MealsCompanion data) {
    return Meal(
      localId: data.localId.present ? data.localId.value : this.localId,
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Meal(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      localId, id, createdAt, updatedAt, deletedAt, userId, name, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Meal &&
          other.localId == this.localId &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.notes == this.notes);
}

class MealsCompanion extends UpdateCompanion<Meal> {
  final Value<int> localId;
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> userId;
  final Value<String> name;
  final Value<String?> notes;
  const MealsCompanion({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.notes = const Value.absent(),
  });
  MealsCompanion.insert({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.userId = const Value.absent(),
    required String name,
    this.notes = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Meal> custom({
    Expression<int>? localId,
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (notes != null) 'notes': notes,
    });
  }

  MealsCompanion copyWith(
      {Value<int>? localId,
      Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String?>? userId,
      Value<String>? name,
      Value<String?>? notes}) {
    return MealsCompanion(
      localId: localId ?? this.localId,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealsCompanion(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $MealItemsTable extends MealItems
    with TableInfo<$MealItemsTable, MealItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
      'local_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _mealIdMeta = const VerificationMeta('mealId');
  @override
  late final GeneratedColumn<String> mealId = GeneratedColumn<String>(
      'meal_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES meals (id) ON DELETE CASCADE'));
  static const VerificationMeta _productBarcodeMeta =
      const VerificationMeta('productBarcode');
  @override
  late final GeneratedColumn<String> productBarcode = GeneratedColumn<String>(
      'product_barcode', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES products (id)'));
  static const VerificationMeta _quantityInGramsMeta =
      const VerificationMeta('quantityInGrams');
  @override
  late final GeneratedColumn<int> quantityInGrams = GeneratedColumn<int>(
      'quantity_in_grams', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        id,
        createdAt,
        updatedAt,
        deletedAt,
        mealId,
        productBarcode,
        productId,
        quantityInGrams
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_items';
  @override
  VerificationContext validateIntegrity(Insertable<MealItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('meal_id')) {
      context.handle(_mealIdMeta,
          mealId.isAcceptableOrUnknown(data['meal_id']!, _mealIdMeta));
    } else if (isInserting) {
      context.missing(_mealIdMeta);
    }
    if (data.containsKey('product_barcode')) {
      context.handle(
          _productBarcodeMeta,
          productBarcode.isAcceptableOrUnknown(
              data['product_barcode']!, _productBarcodeMeta));
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    }
    if (data.containsKey('quantity_in_grams')) {
      context.handle(
          _quantityInGramsMeta,
          quantityInGrams.isAcceptableOrUnknown(
              data['quantity_in_grams']!, _quantityInGramsMeta));
    } else if (isInserting) {
      context.missing(_quantityInGramsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  MealItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealItem(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}local_id'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      mealId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meal_id'])!,
      productBarcode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_barcode']),
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id']),
      quantityInGrams: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quantity_in_grams'])!,
    );
  }

  @override
  $MealItemsTable createAlias(String alias) {
    return $MealItemsTable(attachedDatabase, alias);
  }
}

class MealItem extends DataClass implements Insertable<MealItem> {
  final int localId;
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String mealId;
  final String? productBarcode;
  final String? productId;
  final int quantityInGrams;
  const MealItem(
      {required this.localId,
      required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.mealId,
      this.productBarcode,
      this.productId,
      required this.quantityInGrams});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['meal_id'] = Variable<String>(mealId);
    if (!nullToAbsent || productBarcode != null) {
      map['product_barcode'] = Variable<String>(productBarcode);
    }
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<String>(productId);
    }
    map['quantity_in_grams'] = Variable<int>(quantityInGrams);
    return map;
  }

  MealItemsCompanion toCompanion(bool nullToAbsent) {
    return MealItemsCompanion(
      localId: Value(localId),
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      mealId: Value(mealId),
      productBarcode: productBarcode == null && nullToAbsent
          ? const Value.absent()
          : Value(productBarcode),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      quantityInGrams: Value(quantityInGrams),
    );
  }

  factory MealItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealItem(
      localId: serializer.fromJson<int>(json['localId']),
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      mealId: serializer.fromJson<String>(json['mealId']),
      productBarcode: serializer.fromJson<String?>(json['productBarcode']),
      productId: serializer.fromJson<String?>(json['productId']),
      quantityInGrams: serializer.fromJson<int>(json['quantityInGrams']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'mealId': serializer.toJson<String>(mealId),
      'productBarcode': serializer.toJson<String?>(productBarcode),
      'productId': serializer.toJson<String?>(productId),
      'quantityInGrams': serializer.toJson<int>(quantityInGrams),
    };
  }

  MealItem copyWith(
          {int? localId,
          String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? mealId,
          Value<String?> productBarcode = const Value.absent(),
          Value<String?> productId = const Value.absent(),
          int? quantityInGrams}) =>
      MealItem(
        localId: localId ?? this.localId,
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        mealId: mealId ?? this.mealId,
        productBarcode:
            productBarcode.present ? productBarcode.value : this.productBarcode,
        productId: productId.present ? productId.value : this.productId,
        quantityInGrams: quantityInGrams ?? this.quantityInGrams,
      );
  MealItem copyWithCompanion(MealItemsCompanion data) {
    return MealItem(
      localId: data.localId.present ? data.localId.value : this.localId,
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      mealId: data.mealId.present ? data.mealId.value : this.mealId,
      productBarcode: data.productBarcode.present
          ? data.productBarcode.value
          : this.productBarcode,
      productId: data.productId.present ? data.productId.value : this.productId,
      quantityInGrams: data.quantityInGrams.present
          ? data.quantityInGrams.value
          : this.quantityInGrams,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealItem(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('mealId: $mealId, ')
          ..write('productBarcode: $productBarcode, ')
          ..write('productId: $productId, ')
          ..write('quantityInGrams: $quantityInGrams')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(localId, id, createdAt, updatedAt, deletedAt,
      mealId, productBarcode, productId, quantityInGrams);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealItem &&
          other.localId == this.localId &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.mealId == this.mealId &&
          other.productBarcode == this.productBarcode &&
          other.productId == this.productId &&
          other.quantityInGrams == this.quantityInGrams);
}

class MealItemsCompanion extends UpdateCompanion<MealItem> {
  final Value<int> localId;
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> mealId;
  final Value<String?> productBarcode;
  final Value<String?> productId;
  final Value<int> quantityInGrams;
  const MealItemsCompanion({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.mealId = const Value.absent(),
    this.productBarcode = const Value.absent(),
    this.productId = const Value.absent(),
    this.quantityInGrams = const Value.absent(),
  });
  MealItemsCompanion.insert({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String mealId,
    this.productBarcode = const Value.absent(),
    this.productId = const Value.absent(),
    required int quantityInGrams,
  })  : mealId = Value(mealId),
        quantityInGrams = Value(quantityInGrams);
  static Insertable<MealItem> custom({
    Expression<int>? localId,
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? mealId,
    Expression<String>? productBarcode,
    Expression<String>? productId,
    Expression<int>? quantityInGrams,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (mealId != null) 'meal_id': mealId,
      if (productBarcode != null) 'product_barcode': productBarcode,
      if (productId != null) 'product_id': productId,
      if (quantityInGrams != null) 'quantity_in_grams': quantityInGrams,
    });
  }

  MealItemsCompanion copyWith(
      {Value<int>? localId,
      Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? mealId,
      Value<String?>? productBarcode,
      Value<String?>? productId,
      Value<int>? quantityInGrams}) {
    return MealItemsCompanion(
      localId: localId ?? this.localId,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      mealId: mealId ?? this.mealId,
      productBarcode: productBarcode ?? this.productBarcode,
      productId: productId ?? this.productId,
      quantityInGrams: quantityInGrams ?? this.quantityInGrams,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (mealId.present) {
      map['meal_id'] = Variable<String>(mealId.value);
    }
    if (productBarcode.present) {
      map['product_barcode'] = Variable<String>(productBarcode.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (quantityInGrams.present) {
      map['quantity_in_grams'] = Variable<int>(quantityInGrams.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealItemsCompanion(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('mealId: $mealId, ')
          ..write('productBarcode: $productBarcode, ')
          ..write('productId: $productId, ')
          ..write('quantityInGrams: $quantityInGrams')
          ..write(')'))
        .toString();
  }
}

class $FoodCategoriesTable extends FoodCategories
    with TableInfo<$FoodCategoriesTable, FoodCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameDeMeta = const VerificationMeta('nameDe');
  @override
  late final GeneratedColumn<String> nameDe = GeneratedColumn<String>(
      'name_de', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
      'name_en', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
      'emoji', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [key, nameDe, nameEn, emoji];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'food_categories';
  @override
  VerificationContext validateIntegrity(Insertable<FoodCategory> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('name_de')) {
      context.handle(_nameDeMeta,
          nameDe.isAcceptableOrUnknown(data['name_de']!, _nameDeMeta));
    }
    if (data.containsKey('name_en')) {
      context.handle(_nameEnMeta,
          nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta));
    }
    if (data.containsKey('emoji')) {
      context.handle(
          _emojiMeta, emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  FoodCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoodCategory(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      nameDe: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_de']),
      nameEn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_en']),
      emoji: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}emoji']),
    );
  }

  @override
  $FoodCategoriesTable createAlias(String alias) {
    return $FoodCategoriesTable(attachedDatabase, alias);
  }
}

class FoodCategory extends DataClass implements Insertable<FoodCategory> {
  final String key;
  final String? nameDe;
  final String? nameEn;
  final String? emoji;
  const FoodCategory({required this.key, this.nameDe, this.nameEn, this.emoji});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || nameDe != null) {
      map['name_de'] = Variable<String>(nameDe);
    }
    if (!nullToAbsent || nameEn != null) {
      map['name_en'] = Variable<String>(nameEn);
    }
    if (!nullToAbsent || emoji != null) {
      map['emoji'] = Variable<String>(emoji);
    }
    return map;
  }

  FoodCategoriesCompanion toCompanion(bool nullToAbsent) {
    return FoodCategoriesCompanion(
      key: Value(key),
      nameDe:
          nameDe == null && nullToAbsent ? const Value.absent() : Value(nameDe),
      nameEn:
          nameEn == null && nullToAbsent ? const Value.absent() : Value(nameEn),
      emoji:
          emoji == null && nullToAbsent ? const Value.absent() : Value(emoji),
    );
  }

  factory FoodCategory.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoodCategory(
      key: serializer.fromJson<String>(json['key']),
      nameDe: serializer.fromJson<String?>(json['nameDe']),
      nameEn: serializer.fromJson<String?>(json['nameEn']),
      emoji: serializer.fromJson<String?>(json['emoji']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'nameDe': serializer.toJson<String?>(nameDe),
      'nameEn': serializer.toJson<String?>(nameEn),
      'emoji': serializer.toJson<String?>(emoji),
    };
  }

  FoodCategory copyWith(
          {String? key,
          Value<String?> nameDe = const Value.absent(),
          Value<String?> nameEn = const Value.absent(),
          Value<String?> emoji = const Value.absent()}) =>
      FoodCategory(
        key: key ?? this.key,
        nameDe: nameDe.present ? nameDe.value : this.nameDe,
        nameEn: nameEn.present ? nameEn.value : this.nameEn,
        emoji: emoji.present ? emoji.value : this.emoji,
      );
  FoodCategory copyWithCompanion(FoodCategoriesCompanion data) {
    return FoodCategory(
      key: data.key.present ? data.key.value : this.key,
      nameDe: data.nameDe.present ? data.nameDe.value : this.nameDe,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoodCategory(')
          ..write('key: $key, ')
          ..write('nameDe: $nameDe, ')
          ..write('nameEn: $nameEn, ')
          ..write('emoji: $emoji')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, nameDe, nameEn, emoji);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodCategory &&
          other.key == this.key &&
          other.nameDe == this.nameDe &&
          other.nameEn == this.nameEn &&
          other.emoji == this.emoji);
}

class FoodCategoriesCompanion extends UpdateCompanion<FoodCategory> {
  final Value<String> key;
  final Value<String?> nameDe;
  final Value<String?> nameEn;
  final Value<String?> emoji;
  final Value<int> rowid;
  const FoodCategoriesCompanion({
    this.key = const Value.absent(),
    this.nameDe = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.emoji = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoodCategoriesCompanion.insert({
    required String key,
    this.nameDe = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.emoji = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<FoodCategory> custom({
    Expression<String>? key,
    Expression<String>? nameDe,
    Expression<String>? nameEn,
    Expression<String>? emoji,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (nameDe != null) 'name_de': nameDe,
      if (nameEn != null) 'name_en': nameEn,
      if (emoji != null) 'emoji': emoji,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoodCategoriesCompanion copyWith(
      {Value<String>? key,
      Value<String?>? nameDe,
      Value<String?>? nameEn,
      Value<String?>? emoji,
      Value<int>? rowid}) {
    return FoodCategoriesCompanion(
      key: key ?? this.key,
      nameDe: nameDe ?? this.nameDe,
      nameEn: nameEn ?? this.nameEn,
      emoji: emoji ?? this.emoji,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (nameDe.present) {
      map['name_de'] = Variable<String>(nameDe.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodCategoriesCompanion(')
          ..write('key: $key, ')
          ..write('nameDe: $nameDe, ')
          ..write('nameEn: $nameEn, ')
          ..write('emoji: $emoji, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FavoritesTable extends Favorites
    with TableInfo<$FavoritesTable, Favorite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _barcodeMeta =
      const VerificationMeta('barcode');
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
      'barcode', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [createdAt, updatedAt, deletedAt, barcode];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorites';
  @override
  VerificationContext validateIntegrity(Insertable<Favorite> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('barcode')) {
      context.handle(_barcodeMeta,
          barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta));
    } else if (isInserting) {
      context.missing(_barcodeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {barcode};
  @override
  Favorite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Favorite(
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      barcode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}barcode'])!,
    );
  }

  @override
  $FavoritesTable createAlias(String alias) {
    return $FavoritesTable(attachedDatabase, alias);
  }
}

class Favorite extends DataClass implements Insertable<Favorite> {
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String barcode;
  const Favorite(
      {required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.barcode});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['barcode'] = Variable<String>(barcode);
    return map;
  }

  FavoritesCompanion toCompanion(bool nullToAbsent) {
    return FavoritesCompanion(
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      barcode: Value(barcode),
    );
  }

  factory Favorite.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Favorite(
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      barcode: serializer.fromJson<String>(json['barcode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'barcode': serializer.toJson<String>(barcode),
    };
  }

  Favorite copyWith(
          {DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? barcode}) =>
      Favorite(
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        barcode: barcode ?? this.barcode,
      );
  Favorite copyWithCompanion(FavoritesCompanion data) {
    return Favorite(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Favorite(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('barcode: $barcode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(createdAt, updatedAt, deletedAt, barcode);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Favorite &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.barcode == this.barcode);
}

class FavoritesCompanion extends UpdateCompanion<Favorite> {
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> barcode;
  final Value<int> rowid;
  const FavoritesCompanion({
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.barcode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavoritesCompanion.insert({
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String barcode,
    this.rowid = const Value.absent(),
  }) : barcode = Value(barcode);
  static Insertable<Favorite> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? barcode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (barcode != null) 'barcode': barcode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavoritesCompanion copyWith(
      {Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? barcode,
      Value<int>? rowid}) {
    return FavoritesCompanion(
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      barcode: barcode ?? this.barcode,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('barcode: $barcode, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyGoalsHistoryTable extends DailyGoalsHistory
    with TableInfo<$DailyGoalsHistoryTable, DailyGoalsHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyGoalsHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
      'local_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _targetCaloriesMeta =
      const VerificationMeta('targetCalories');
  @override
  late final GeneratedColumn<int> targetCalories = GeneratedColumn<int>(
      'target_calories', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _targetProteinMeta =
      const VerificationMeta('targetProtein');
  @override
  late final GeneratedColumn<int> targetProtein = GeneratedColumn<int>(
      'target_protein', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _targetCarbsMeta =
      const VerificationMeta('targetCarbs');
  @override
  late final GeneratedColumn<int> targetCarbs = GeneratedColumn<int>(
      'target_carbs', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _targetFatMeta =
      const VerificationMeta('targetFat');
  @override
  late final GeneratedColumn<int> targetFat = GeneratedColumn<int>(
      'target_fat', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _targetWaterMeta =
      const VerificationMeta('targetWater');
  @override
  late final GeneratedColumn<int> targetWater = GeneratedColumn<int>(
      'target_water', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _targetStepsMeta =
      const VerificationMeta('targetSteps');
  @override
  late final GeneratedColumn<int> targetSteps = GeneratedColumn<int>(
      'target_steps', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(8000));
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        id,
        createdAt,
        updatedAt,
        deletedAt,
        targetCalories,
        targetProtein,
        targetCarbs,
        targetFat,
        targetWater,
        targetSteps
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_goals_history';
  @override
  VerificationContext validateIntegrity(
      Insertable<DailyGoalsHistoryData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('target_calories')) {
      context.handle(
          _targetCaloriesMeta,
          targetCalories.isAcceptableOrUnknown(
              data['target_calories']!, _targetCaloriesMeta));
    } else if (isInserting) {
      context.missing(_targetCaloriesMeta);
    }
    if (data.containsKey('target_protein')) {
      context.handle(
          _targetProteinMeta,
          targetProtein.isAcceptableOrUnknown(
              data['target_protein']!, _targetProteinMeta));
    } else if (isInserting) {
      context.missing(_targetProteinMeta);
    }
    if (data.containsKey('target_carbs')) {
      context.handle(
          _targetCarbsMeta,
          targetCarbs.isAcceptableOrUnknown(
              data['target_carbs']!, _targetCarbsMeta));
    } else if (isInserting) {
      context.missing(_targetCarbsMeta);
    }
    if (data.containsKey('target_fat')) {
      context.handle(_targetFatMeta,
          targetFat.isAcceptableOrUnknown(data['target_fat']!, _targetFatMeta));
    } else if (isInserting) {
      context.missing(_targetFatMeta);
    }
    if (data.containsKey('target_water')) {
      context.handle(
          _targetWaterMeta,
          targetWater.isAcceptableOrUnknown(
              data['target_water']!, _targetWaterMeta));
    } else if (isInserting) {
      context.missing(_targetWaterMeta);
    }
    if (data.containsKey('target_steps')) {
      context.handle(
          _targetStepsMeta,
          targetSteps.isAcceptableOrUnknown(
              data['target_steps']!, _targetStepsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  DailyGoalsHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyGoalsHistoryData(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}local_id'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      targetCalories: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_calories'])!,
      targetProtein: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_protein'])!,
      targetCarbs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_carbs'])!,
      targetFat: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_fat'])!,
      targetWater: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_water'])!,
      targetSteps: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_steps'])!,
    );
  }

  @override
  $DailyGoalsHistoryTable createAlias(String alias) {
    return $DailyGoalsHistoryTable(attachedDatabase, alias);
  }
}

class DailyGoalsHistoryData extends DataClass
    implements Insertable<DailyGoalsHistoryData> {
  final int localId;
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int targetCalories;
  final int targetProtein;
  final int targetCarbs;
  final int targetFat;
  final int targetWater;
  final int targetSteps;
  const DailyGoalsHistoryData(
      {required this.localId,
      required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.targetCalories,
      required this.targetProtein,
      required this.targetCarbs,
      required this.targetFat,
      required this.targetWater,
      required this.targetSteps});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['target_calories'] = Variable<int>(targetCalories);
    map['target_protein'] = Variable<int>(targetProtein);
    map['target_carbs'] = Variable<int>(targetCarbs);
    map['target_fat'] = Variable<int>(targetFat);
    map['target_water'] = Variable<int>(targetWater);
    map['target_steps'] = Variable<int>(targetSteps);
    return map;
  }

  DailyGoalsHistoryCompanion toCompanion(bool nullToAbsent) {
    return DailyGoalsHistoryCompanion(
      localId: Value(localId),
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      targetCalories: Value(targetCalories),
      targetProtein: Value(targetProtein),
      targetCarbs: Value(targetCarbs),
      targetFat: Value(targetFat),
      targetWater: Value(targetWater),
      targetSteps: Value(targetSteps),
    );
  }

  factory DailyGoalsHistoryData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyGoalsHistoryData(
      localId: serializer.fromJson<int>(json['localId']),
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      targetCalories: serializer.fromJson<int>(json['targetCalories']),
      targetProtein: serializer.fromJson<int>(json['targetProtein']),
      targetCarbs: serializer.fromJson<int>(json['targetCarbs']),
      targetFat: serializer.fromJson<int>(json['targetFat']),
      targetWater: serializer.fromJson<int>(json['targetWater']),
      targetSteps: serializer.fromJson<int>(json['targetSteps']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'targetCalories': serializer.toJson<int>(targetCalories),
      'targetProtein': serializer.toJson<int>(targetProtein),
      'targetCarbs': serializer.toJson<int>(targetCarbs),
      'targetFat': serializer.toJson<int>(targetFat),
      'targetWater': serializer.toJson<int>(targetWater),
      'targetSteps': serializer.toJson<int>(targetSteps),
    };
  }

  DailyGoalsHistoryData copyWith(
          {int? localId,
          String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          int? targetCalories,
          int? targetProtein,
          int? targetCarbs,
          int? targetFat,
          int? targetWater,
          int? targetSteps}) =>
      DailyGoalsHistoryData(
        localId: localId ?? this.localId,
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        targetCalories: targetCalories ?? this.targetCalories,
        targetProtein: targetProtein ?? this.targetProtein,
        targetCarbs: targetCarbs ?? this.targetCarbs,
        targetFat: targetFat ?? this.targetFat,
        targetWater: targetWater ?? this.targetWater,
        targetSteps: targetSteps ?? this.targetSteps,
      );
  DailyGoalsHistoryData copyWithCompanion(DailyGoalsHistoryCompanion data) {
    return DailyGoalsHistoryData(
      localId: data.localId.present ? data.localId.value : this.localId,
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      targetCalories: data.targetCalories.present
          ? data.targetCalories.value
          : this.targetCalories,
      targetProtein: data.targetProtein.present
          ? data.targetProtein.value
          : this.targetProtein,
      targetCarbs:
          data.targetCarbs.present ? data.targetCarbs.value : this.targetCarbs,
      targetFat: data.targetFat.present ? data.targetFat.value : this.targetFat,
      targetWater:
          data.targetWater.present ? data.targetWater.value : this.targetWater,
      targetSteps:
          data.targetSteps.present ? data.targetSteps.value : this.targetSteps,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyGoalsHistoryData(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('targetCalories: $targetCalories, ')
          ..write('targetProtein: $targetProtein, ')
          ..write('targetCarbs: $targetCarbs, ')
          ..write('targetFat: $targetFat, ')
          ..write('targetWater: $targetWater, ')
          ..write('targetSteps: $targetSteps')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      localId,
      id,
      createdAt,
      updatedAt,
      deletedAt,
      targetCalories,
      targetProtein,
      targetCarbs,
      targetFat,
      targetWater,
      targetSteps);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyGoalsHistoryData &&
          other.localId == this.localId &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.targetCalories == this.targetCalories &&
          other.targetProtein == this.targetProtein &&
          other.targetCarbs == this.targetCarbs &&
          other.targetFat == this.targetFat &&
          other.targetWater == this.targetWater &&
          other.targetSteps == this.targetSteps);
}

class DailyGoalsHistoryCompanion
    extends UpdateCompanion<DailyGoalsHistoryData> {
  final Value<int> localId;
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> targetCalories;
  final Value<int> targetProtein;
  final Value<int> targetCarbs;
  final Value<int> targetFat;
  final Value<int> targetWater;
  final Value<int> targetSteps;
  const DailyGoalsHistoryCompanion({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.targetCalories = const Value.absent(),
    this.targetProtein = const Value.absent(),
    this.targetCarbs = const Value.absent(),
    this.targetFat = const Value.absent(),
    this.targetWater = const Value.absent(),
    this.targetSteps = const Value.absent(),
  });
  DailyGoalsHistoryCompanion.insert({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required int targetCalories,
    required int targetProtein,
    required int targetCarbs,
    required int targetFat,
    required int targetWater,
    this.targetSteps = const Value.absent(),
  })  : targetCalories = Value(targetCalories),
        targetProtein = Value(targetProtein),
        targetCarbs = Value(targetCarbs),
        targetFat = Value(targetFat),
        targetWater = Value(targetWater);
  static Insertable<DailyGoalsHistoryData> custom({
    Expression<int>? localId,
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? targetCalories,
    Expression<int>? targetProtein,
    Expression<int>? targetCarbs,
    Expression<int>? targetFat,
    Expression<int>? targetWater,
    Expression<int>? targetSteps,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (targetCalories != null) 'target_calories': targetCalories,
      if (targetProtein != null) 'target_protein': targetProtein,
      if (targetCarbs != null) 'target_carbs': targetCarbs,
      if (targetFat != null) 'target_fat': targetFat,
      if (targetWater != null) 'target_water': targetWater,
      if (targetSteps != null) 'target_steps': targetSteps,
    });
  }

  DailyGoalsHistoryCompanion copyWith(
      {Value<int>? localId,
      Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? targetCalories,
      Value<int>? targetProtein,
      Value<int>? targetCarbs,
      Value<int>? targetFat,
      Value<int>? targetWater,
      Value<int>? targetSteps}) {
    return DailyGoalsHistoryCompanion(
      localId: localId ?? this.localId,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      targetCalories: targetCalories ?? this.targetCalories,
      targetProtein: targetProtein ?? this.targetProtein,
      targetCarbs: targetCarbs ?? this.targetCarbs,
      targetFat: targetFat ?? this.targetFat,
      targetWater: targetWater ?? this.targetWater,
      targetSteps: targetSteps ?? this.targetSteps,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (targetCalories.present) {
      map['target_calories'] = Variable<int>(targetCalories.value);
    }
    if (targetProtein.present) {
      map['target_protein'] = Variable<int>(targetProtein.value);
    }
    if (targetCarbs.present) {
      map['target_carbs'] = Variable<int>(targetCarbs.value);
    }
    if (targetFat.present) {
      map['target_fat'] = Variable<int>(targetFat.value);
    }
    if (targetWater.present) {
      map['target_water'] = Variable<int>(targetWater.value);
    }
    if (targetSteps.present) {
      map['target_steps'] = Variable<int>(targetSteps.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyGoalsHistoryCompanion(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('targetCalories: $targetCalories, ')
          ..write('targetProtein: $targetProtein, ')
          ..write('targetCarbs: $targetCarbs, ')
          ..write('targetFat: $targetFat, ')
          ..write('targetWater: $targetWater, ')
          ..write('targetSteps: $targetSteps')
          ..write(')'))
        .toString();
  }
}

class $SupplementSettingsHistoryTable extends SupplementSettingsHistory
    with
        TableInfo<$SupplementSettingsHistoryTable,
            SupplementSettingsHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SupplementSettingsHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
      'local_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _supplementIdMeta =
      const VerificationMeta('supplementId');
  @override
  late final GeneratedColumn<String> supplementId = GeneratedColumn<String>(
      'supplement_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES supplements (id) ON DELETE CASCADE'));
  static const VerificationMeta _isTrackedMeta =
      const VerificationMeta('isTracked');
  @override
  late final GeneratedColumn<bool> isTracked = GeneratedColumn<bool>(
      'is_tracked', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_tracked" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _doseMeta = const VerificationMeta('dose');
  @override
  late final GeneratedColumn<double> dose = GeneratedColumn<double>(
      'dose', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _dailyGoalMeta =
      const VerificationMeta('dailyGoal');
  @override
  late final GeneratedColumn<double> dailyGoal = GeneratedColumn<double>(
      'daily_goal', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _dailyLimitMeta =
      const VerificationMeta('dailyLimit');
  @override
  late final GeneratedColumn<double> dailyLimit = GeneratedColumn<double>(
      'daily_limit', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        id,
        createdAt,
        updatedAt,
        deletedAt,
        supplementId,
        isTracked,
        dose,
        dailyGoal,
        dailyLimit
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'supplement_settings_history';
  @override
  VerificationContext validateIntegrity(
      Insertable<SupplementSettingsHistoryData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('supplement_id')) {
      context.handle(
          _supplementIdMeta,
          supplementId.isAcceptableOrUnknown(
              data['supplement_id']!, _supplementIdMeta));
    } else if (isInserting) {
      context.missing(_supplementIdMeta);
    }
    if (data.containsKey('is_tracked')) {
      context.handle(_isTrackedMeta,
          isTracked.isAcceptableOrUnknown(data['is_tracked']!, _isTrackedMeta));
    }
    if (data.containsKey('dose')) {
      context.handle(
          _doseMeta, dose.isAcceptableOrUnknown(data['dose']!, _doseMeta));
    } else if (isInserting) {
      context.missing(_doseMeta);
    }
    if (data.containsKey('daily_goal')) {
      context.handle(_dailyGoalMeta,
          dailyGoal.isAcceptableOrUnknown(data['daily_goal']!, _dailyGoalMeta));
    }
    if (data.containsKey('daily_limit')) {
      context.handle(
          _dailyLimitMeta,
          dailyLimit.isAcceptableOrUnknown(
              data['daily_limit']!, _dailyLimitMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  SupplementSettingsHistoryData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SupplementSettingsHistoryData(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}local_id'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      supplementId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}supplement_id'])!,
      isTracked: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_tracked'])!,
      dose: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}dose'])!,
      dailyGoal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}daily_goal']),
      dailyLimit: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}daily_limit']),
    );
  }

  @override
  $SupplementSettingsHistoryTable createAlias(String alias) {
    return $SupplementSettingsHistoryTable(attachedDatabase, alias);
  }
}

class SupplementSettingsHistoryData extends DataClass
    implements Insertable<SupplementSettingsHistoryData> {
  final int localId;
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String supplementId;
  final bool isTracked;
  final double dose;
  final double? dailyGoal;
  final double? dailyLimit;
  const SupplementSettingsHistoryData(
      {required this.localId,
      required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.supplementId,
      required this.isTracked,
      required this.dose,
      this.dailyGoal,
      this.dailyLimit});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['supplement_id'] = Variable<String>(supplementId);
    map['is_tracked'] = Variable<bool>(isTracked);
    map['dose'] = Variable<double>(dose);
    if (!nullToAbsent || dailyGoal != null) {
      map['daily_goal'] = Variable<double>(dailyGoal);
    }
    if (!nullToAbsent || dailyLimit != null) {
      map['daily_limit'] = Variable<double>(dailyLimit);
    }
    return map;
  }

  SupplementSettingsHistoryCompanion toCompanion(bool nullToAbsent) {
    return SupplementSettingsHistoryCompanion(
      localId: Value(localId),
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      supplementId: Value(supplementId),
      isTracked: Value(isTracked),
      dose: Value(dose),
      dailyGoal: dailyGoal == null && nullToAbsent
          ? const Value.absent()
          : Value(dailyGoal),
      dailyLimit: dailyLimit == null && nullToAbsent
          ? const Value.absent()
          : Value(dailyLimit),
    );
  }

  factory SupplementSettingsHistoryData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SupplementSettingsHistoryData(
      localId: serializer.fromJson<int>(json['localId']),
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      supplementId: serializer.fromJson<String>(json['supplementId']),
      isTracked: serializer.fromJson<bool>(json['isTracked']),
      dose: serializer.fromJson<double>(json['dose']),
      dailyGoal: serializer.fromJson<double?>(json['dailyGoal']),
      dailyLimit: serializer.fromJson<double?>(json['dailyLimit']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'supplementId': serializer.toJson<String>(supplementId),
      'isTracked': serializer.toJson<bool>(isTracked),
      'dose': serializer.toJson<double>(dose),
      'dailyGoal': serializer.toJson<double?>(dailyGoal),
      'dailyLimit': serializer.toJson<double?>(dailyLimit),
    };
  }

  SupplementSettingsHistoryData copyWith(
          {int? localId,
          String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? supplementId,
          bool? isTracked,
          double? dose,
          Value<double?> dailyGoal = const Value.absent(),
          Value<double?> dailyLimit = const Value.absent()}) =>
      SupplementSettingsHistoryData(
        localId: localId ?? this.localId,
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        supplementId: supplementId ?? this.supplementId,
        isTracked: isTracked ?? this.isTracked,
        dose: dose ?? this.dose,
        dailyGoal: dailyGoal.present ? dailyGoal.value : this.dailyGoal,
        dailyLimit: dailyLimit.present ? dailyLimit.value : this.dailyLimit,
      );
  SupplementSettingsHistoryData copyWithCompanion(
      SupplementSettingsHistoryCompanion data) {
    return SupplementSettingsHistoryData(
      localId: data.localId.present ? data.localId.value : this.localId,
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      supplementId: data.supplementId.present
          ? data.supplementId.value
          : this.supplementId,
      isTracked: data.isTracked.present ? data.isTracked.value : this.isTracked,
      dose: data.dose.present ? data.dose.value : this.dose,
      dailyGoal: data.dailyGoal.present ? data.dailyGoal.value : this.dailyGoal,
      dailyLimit:
          data.dailyLimit.present ? data.dailyLimit.value : this.dailyLimit,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SupplementSettingsHistoryData(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('supplementId: $supplementId, ')
          ..write('isTracked: $isTracked, ')
          ..write('dose: $dose, ')
          ..write('dailyGoal: $dailyGoal, ')
          ..write('dailyLimit: $dailyLimit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(localId, id, createdAt, updatedAt, deletedAt,
      supplementId, isTracked, dose, dailyGoal, dailyLimit);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SupplementSettingsHistoryData &&
          other.localId == this.localId &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.supplementId == this.supplementId &&
          other.isTracked == this.isTracked &&
          other.dose == this.dose &&
          other.dailyGoal == this.dailyGoal &&
          other.dailyLimit == this.dailyLimit);
}

class SupplementSettingsHistoryCompanion
    extends UpdateCompanion<SupplementSettingsHistoryData> {
  final Value<int> localId;
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> supplementId;
  final Value<bool> isTracked;
  final Value<double> dose;
  final Value<double?> dailyGoal;
  final Value<double?> dailyLimit;
  const SupplementSettingsHistoryCompanion({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.supplementId = const Value.absent(),
    this.isTracked = const Value.absent(),
    this.dose = const Value.absent(),
    this.dailyGoal = const Value.absent(),
    this.dailyLimit = const Value.absent(),
  });
  SupplementSettingsHistoryCompanion.insert({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String supplementId,
    this.isTracked = const Value.absent(),
    required double dose,
    this.dailyGoal = const Value.absent(),
    this.dailyLimit = const Value.absent(),
  })  : supplementId = Value(supplementId),
        dose = Value(dose);
  static Insertable<SupplementSettingsHistoryData> custom({
    Expression<int>? localId,
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? supplementId,
    Expression<bool>? isTracked,
    Expression<double>? dose,
    Expression<double>? dailyGoal,
    Expression<double>? dailyLimit,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (supplementId != null) 'supplement_id': supplementId,
      if (isTracked != null) 'is_tracked': isTracked,
      if (dose != null) 'dose': dose,
      if (dailyGoal != null) 'daily_goal': dailyGoal,
      if (dailyLimit != null) 'daily_limit': dailyLimit,
    });
  }

  SupplementSettingsHistoryCompanion copyWith(
      {Value<int>? localId,
      Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? supplementId,
      Value<bool>? isTracked,
      Value<double>? dose,
      Value<double?>? dailyGoal,
      Value<double?>? dailyLimit}) {
    return SupplementSettingsHistoryCompanion(
      localId: localId ?? this.localId,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      supplementId: supplementId ?? this.supplementId,
      isTracked: isTracked ?? this.isTracked,
      dose: dose ?? this.dose,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      dailyLimit: dailyLimit ?? this.dailyLimit,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (supplementId.present) {
      map['supplement_id'] = Variable<String>(supplementId.value);
    }
    if (isTracked.present) {
      map['is_tracked'] = Variable<bool>(isTracked.value);
    }
    if (dose.present) {
      map['dose'] = Variable<double>(dose.value);
    }
    if (dailyGoal.present) {
      map['daily_goal'] = Variable<double>(dailyGoal.value);
    }
    if (dailyLimit.present) {
      map['daily_limit'] = Variable<double>(dailyLimit.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SupplementSettingsHistoryCompanion(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('supplementId: $supplementId, ')
          ..write('isTracked: $isTracked, ')
          ..write('dose: $dose, ')
          ..write('dailyGoal: $dailyGoal, ')
          ..write('dailyLimit: $dailyLimit')
          ..write(')'))
        .toString();
  }
}

class $HealthStepSegmentsTable extends HealthStepSegments
    with TableInfo<$HealthStepSegmentsTable, HealthStepSegment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HealthStepSegmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
      'local_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _providerMeta =
      const VerificationMeta('provider');
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
      'provider', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceIdMeta =
      const VerificationMeta('sourceId');
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
      'source_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startAtMeta =
      const VerificationMeta('startAt');
  @override
  late final GeneratedColumn<DateTime> startAt = GeneratedColumn<DateTime>(
      'start_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endAtMeta = const VerificationMeta('endAt');
  @override
  late final GeneratedColumn<DateTime> endAt = GeneratedColumn<DateTime>(
      'end_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _stepCountMeta =
      const VerificationMeta('stepCount');
  @override
  late final GeneratedColumn<int> stepCount = GeneratedColumn<int>(
      'step_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _externalKeyMeta =
      const VerificationMeta('externalKey');
  @override
  late final GeneratedColumn<String> externalKey = GeneratedColumn<String>(
      'external_key', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        id,
        createdAt,
        updatedAt,
        deletedAt,
        provider,
        sourceId,
        startAt,
        endAt,
        stepCount,
        externalKey
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'health_step_segments';
  @override
  VerificationContext validateIntegrity(Insertable<HealthStepSegment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('provider')) {
      context.handle(_providerMeta,
          provider.isAcceptableOrUnknown(data['provider']!, _providerMeta));
    } else if (isInserting) {
      context.missing(_providerMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(_sourceIdMeta,
          sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta));
    }
    if (data.containsKey('start_at')) {
      context.handle(_startAtMeta,
          startAt.isAcceptableOrUnknown(data['start_at']!, _startAtMeta));
    } else if (isInserting) {
      context.missing(_startAtMeta);
    }
    if (data.containsKey('end_at')) {
      context.handle(
          _endAtMeta, endAt.isAcceptableOrUnknown(data['end_at']!, _endAtMeta));
    } else if (isInserting) {
      context.missing(_endAtMeta);
    }
    if (data.containsKey('step_count')) {
      context.handle(_stepCountMeta,
          stepCount.isAcceptableOrUnknown(data['step_count']!, _stepCountMeta));
    } else if (isInserting) {
      context.missing(_stepCountMeta);
    }
    if (data.containsKey('external_key')) {
      context.handle(
          _externalKeyMeta,
          externalKey.isAcceptableOrUnknown(
              data['external_key']!, _externalKeyMeta));
    } else if (isInserting) {
      context.missing(_externalKeyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  HealthStepSegment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HealthStepSegment(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}local_id'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      provider: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider'])!,
      sourceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_id']),
      startAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_at'])!,
      endAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_at'])!,
      stepCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}step_count'])!,
      externalKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}external_key'])!,
    );
  }

  @override
  $HealthStepSegmentsTable createAlias(String alias) {
    return $HealthStepSegmentsTable(attachedDatabase, alias);
  }
}

class HealthStepSegment extends DataClass
    implements Insertable<HealthStepSegment> {
  final int localId;
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String provider;
  final String? sourceId;
  final DateTime startAt;
  final DateTime endAt;
  final int stepCount;
  final String externalKey;
  const HealthStepSegment(
      {required this.localId,
      required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.provider,
      this.sourceId,
      required this.startAt,
      required this.endAt,
      required this.stepCount,
      required this.externalKey});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['provider'] = Variable<String>(provider);
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    map['start_at'] = Variable<DateTime>(startAt);
    map['end_at'] = Variable<DateTime>(endAt);
    map['step_count'] = Variable<int>(stepCount);
    map['external_key'] = Variable<String>(externalKey);
    return map;
  }

  HealthStepSegmentsCompanion toCompanion(bool nullToAbsent) {
    return HealthStepSegmentsCompanion(
      localId: Value(localId),
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      provider: Value(provider),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      startAt: Value(startAt),
      endAt: Value(endAt),
      stepCount: Value(stepCount),
      externalKey: Value(externalKey),
    );
  }

  factory HealthStepSegment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HealthStepSegment(
      localId: serializer.fromJson<int>(json['localId']),
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      provider: serializer.fromJson<String>(json['provider']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      startAt: serializer.fromJson<DateTime>(json['startAt']),
      endAt: serializer.fromJson<DateTime>(json['endAt']),
      stepCount: serializer.fromJson<int>(json['stepCount']),
      externalKey: serializer.fromJson<String>(json['externalKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'provider': serializer.toJson<String>(provider),
      'sourceId': serializer.toJson<String?>(sourceId),
      'startAt': serializer.toJson<DateTime>(startAt),
      'endAt': serializer.toJson<DateTime>(endAt),
      'stepCount': serializer.toJson<int>(stepCount),
      'externalKey': serializer.toJson<String>(externalKey),
    };
  }

  HealthStepSegment copyWith(
          {int? localId,
          String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? provider,
          Value<String?> sourceId = const Value.absent(),
          DateTime? startAt,
          DateTime? endAt,
          int? stepCount,
          String? externalKey}) =>
      HealthStepSegment(
        localId: localId ?? this.localId,
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        provider: provider ?? this.provider,
        sourceId: sourceId.present ? sourceId.value : this.sourceId,
        startAt: startAt ?? this.startAt,
        endAt: endAt ?? this.endAt,
        stepCount: stepCount ?? this.stepCount,
        externalKey: externalKey ?? this.externalKey,
      );
  HealthStepSegment copyWithCompanion(HealthStepSegmentsCompanion data) {
    return HealthStepSegment(
      localId: data.localId.present ? data.localId.value : this.localId,
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      provider: data.provider.present ? data.provider.value : this.provider,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      startAt: data.startAt.present ? data.startAt.value : this.startAt,
      endAt: data.endAt.present ? data.endAt.value : this.endAt,
      stepCount: data.stepCount.present ? data.stepCount.value : this.stepCount,
      externalKey:
          data.externalKey.present ? data.externalKey.value : this.externalKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HealthStepSegment(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('provider: $provider, ')
          ..write('sourceId: $sourceId, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('stepCount: $stepCount, ')
          ..write('externalKey: $externalKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(localId, id, createdAt, updatedAt, deletedAt,
      provider, sourceId, startAt, endAt, stepCount, externalKey);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HealthStepSegment &&
          other.localId == this.localId &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.provider == this.provider &&
          other.sourceId == this.sourceId &&
          other.startAt == this.startAt &&
          other.endAt == this.endAt &&
          other.stepCount == this.stepCount &&
          other.externalKey == this.externalKey);
}

class HealthStepSegmentsCompanion extends UpdateCompanion<HealthStepSegment> {
  final Value<int> localId;
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> provider;
  final Value<String?> sourceId;
  final Value<DateTime> startAt;
  final Value<DateTime> endAt;
  final Value<int> stepCount;
  final Value<String> externalKey;
  const HealthStepSegmentsCompanion({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.provider = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.startAt = const Value.absent(),
    this.endAt = const Value.absent(),
    this.stepCount = const Value.absent(),
    this.externalKey = const Value.absent(),
  });
  HealthStepSegmentsCompanion.insert({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String provider,
    this.sourceId = const Value.absent(),
    required DateTime startAt,
    required DateTime endAt,
    required int stepCount,
    required String externalKey,
  })  : provider = Value(provider),
        startAt = Value(startAt),
        endAt = Value(endAt),
        stepCount = Value(stepCount),
        externalKey = Value(externalKey);
  static Insertable<HealthStepSegment> custom({
    Expression<int>? localId,
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? provider,
    Expression<String>? sourceId,
    Expression<DateTime>? startAt,
    Expression<DateTime>? endAt,
    Expression<int>? stepCount,
    Expression<String>? externalKey,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (provider != null) 'provider': provider,
      if (sourceId != null) 'source_id': sourceId,
      if (startAt != null) 'start_at': startAt,
      if (endAt != null) 'end_at': endAt,
      if (stepCount != null) 'step_count': stepCount,
      if (externalKey != null) 'external_key': externalKey,
    });
  }

  HealthStepSegmentsCompanion copyWith(
      {Value<int>? localId,
      Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? provider,
      Value<String?>? sourceId,
      Value<DateTime>? startAt,
      Value<DateTime>? endAt,
      Value<int>? stepCount,
      Value<String>? externalKey}) {
    return HealthStepSegmentsCompanion(
      localId: localId ?? this.localId,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      provider: provider ?? this.provider,
      sourceId: sourceId ?? this.sourceId,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      stepCount: stepCount ?? this.stepCount,
      externalKey: externalKey ?? this.externalKey,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (startAt.present) {
      map['start_at'] = Variable<DateTime>(startAt.value);
    }
    if (endAt.present) {
      map['end_at'] = Variable<DateTime>(endAt.value);
    }
    if (stepCount.present) {
      map['step_count'] = Variable<int>(stepCount.value);
    }
    if (externalKey.present) {
      map['external_key'] = Variable<String>(externalKey.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HealthStepSegmentsCompanion(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('provider: $provider, ')
          ..write('sourceId: $sourceId, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('stepCount: $stepCount, ')
          ..write('externalKey: $externalKey')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $ExercisesTable exercises = $ExercisesTable(this);
  late final $RoutinesTable routines = $RoutinesTable(this);
  late final $RoutineExercisesTable routineExercises =
      $RoutineExercisesTable(this);
  late final $RoutineSetTemplatesTable routineSetTemplates =
      $RoutineSetTemplatesTable(this);
  late final $WorkoutLogsTable workoutLogs = $WorkoutLogsTable(this);
  late final $SetLogsTable setLogs = $SetLogsTable(this);
  late final $CardioActivitiesTable cardioActivities =
      $CardioActivitiesTable(this);
  late final $CardioSamplesTable cardioSamples = $CardioSamplesTable(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $NutritionLogsTable nutritionLogs = $NutritionLogsTable(this);
  late final $SupplementsTable supplements = $SupplementsTable(this);
  late final $SupplementLogsTable supplementLogs = $SupplementLogsTable(this);
  late final $FluidLogsTable fluidLogs = $FluidLogsTable(this);
  late final $MeasurementsTable measurements = $MeasurementsTable(this);
  late final $PostsTable posts = $PostsTable(this);
  late final $SocialInteractionsTable socialInteractions =
      $SocialInteractionsTable(this);
  late final $MealsTable meals = $MealsTable(this);
  late final $MealItemsTable mealItems = $MealItemsTable(this);
  late final $FoodCategoriesTable foodCategories = $FoodCategoriesTable(this);
  late final $FavoritesTable favorites = $FavoritesTable(this);
  late final $DailyGoalsHistoryTable dailyGoalsHistory =
      $DailyGoalsHistoryTable(this);
  late final $SupplementSettingsHistoryTable supplementSettingsHistory =
      $SupplementSettingsHistoryTable(this);
  late final $HealthStepSegmentsTable healthStepSegments =
      $HealthStepSegmentsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        profiles,
        appSettings,
        exercises,
        routines,
        routineExercises,
        routineSetTemplates,
        workoutLogs,
        setLogs,
        cardioActivities,
        cardioSamples,
        products,
        nutritionLogs,
        supplements,
        supplementLogs,
        fluidLogs,
        measurements,
        posts,
        socialInteractions,
        meals,
        mealItems,
        foodCategories,
        favorites,
        dailyGoalsHistory,
        supplementSettingsHistory,
        healthStepSegments
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('routines',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('routine_exercises', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('routine_exercises',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('routine_set_templates', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('workout_logs',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('set_logs', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('workout_logs',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('cardio_activities', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('cardio_activities',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('cardio_samples', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('supplements',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('supplement_logs', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('nutrition_logs',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('supplement_logs', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('nutrition_logs',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('fluid_logs', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('posts',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('social_interactions', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('meals',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('meal_items', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('supplements',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('supplement_settings_history',
                  kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$ProfilesTableCreateCompanionBuilder = ProfilesCompanion Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> username,
  Value<bool> isCoach,
  Value<String> visibility,
  Value<DateTime?> birthday,
  Value<int?> height,
  Value<String?> gender,
  Value<String?> profileImagePath,
});
typedef $$ProfilesTableUpdateCompanionBuilder = ProfilesCompanion Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> username,
  Value<bool> isCoach,
  Value<String> visibility,
  Value<DateTime?> birthday,
  Value<int?> height,
  Value<String?> gender,
  Value<String?> profileImagePath,
});

final class $$ProfilesTableReferences
    extends BaseReferences<_$AppDatabase, $ProfilesTable, Profile> {
  $$ProfilesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AppSettingsTable, List<AppSetting>>
      _appSettingsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.appSettings,
              aliasName:
                  $_aliasNameGenerator(db.profiles.id, db.appSettings.userId));

  $$AppSettingsTableProcessedTableManager get appSettingsRefs {
    final manager = $$AppSettingsTableTableManager($_db, $_db.appSettings)
        .filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_appSettingsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCoach => $composableBuilder(
      column: $table.isCoach, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get visibility => $composableBuilder(
      column: $table.visibility, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get birthday => $composableBuilder(
      column: $table.birthday, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get gender => $composableBuilder(
      column: $table.gender, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get profileImagePath => $composableBuilder(
      column: $table.profileImagePath,
      builder: (column) => ColumnFilters(column));

  Expression<bool> appSettingsRefs(
      Expression<bool> Function($$AppSettingsTableFilterComposer f) f) {
    final $$AppSettingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.appSettings,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AppSettingsTableFilterComposer(
              $db: $db,
              $table: $db.appSettings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCoach => $composableBuilder(
      column: $table.isCoach, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get visibility => $composableBuilder(
      column: $table.visibility, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get birthday => $composableBuilder(
      column: $table.birthday, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get gender => $composableBuilder(
      column: $table.gender, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get profileImagePath => $composableBuilder(
      column: $table.profileImagePath,
      builder: (column) => ColumnOrderings(column));
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<bool> get isCoach =>
      $composableBuilder(column: $table.isCoach, builder: (column) => column);

  GeneratedColumn<String> get visibility => $composableBuilder(
      column: $table.visibility, builder: (column) => column);

  GeneratedColumn<DateTime> get birthday =>
      $composableBuilder(column: $table.birthday, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<String> get profileImagePath => $composableBuilder(
      column: $table.profileImagePath, builder: (column) => column);

  Expression<T> appSettingsRefs<T extends Object>(
      Expression<T> Function($$AppSettingsTableAnnotationComposer a) f) {
    final $$AppSettingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.appSettings,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AppSettingsTableAnnotationComposer(
              $db: $db,
              $table: $db.appSettings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProfilesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProfilesTable,
    Profile,
    $$ProfilesTableFilterComposer,
    $$ProfilesTableOrderingComposer,
    $$ProfilesTableAnnotationComposer,
    $$ProfilesTableCreateCompanionBuilder,
    $$ProfilesTableUpdateCompanionBuilder,
    (Profile, $$ProfilesTableReferences),
    Profile,
    PrefetchHooks Function({bool appSettingsRefs})> {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String?> username = const Value.absent(),
            Value<bool> isCoach = const Value.absent(),
            Value<String> visibility = const Value.absent(),
            Value<DateTime?> birthday = const Value.absent(),
            Value<int?> height = const Value.absent(),
            Value<String?> gender = const Value.absent(),
            Value<String?> profileImagePath = const Value.absent(),
          }) =>
              ProfilesCompanion(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            username: username,
            isCoach: isCoach,
            visibility: visibility,
            birthday: birthday,
            height: height,
            gender: gender,
            profileImagePath: profileImagePath,
          ),
          createCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String?> username = const Value.absent(),
            Value<bool> isCoach = const Value.absent(),
            Value<String> visibility = const Value.absent(),
            Value<DateTime?> birthday = const Value.absent(),
            Value<int?> height = const Value.absent(),
            Value<String?> gender = const Value.absent(),
            Value<String?> profileImagePath = const Value.absent(),
          }) =>
              ProfilesCompanion.insert(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            username: username,
            isCoach: isCoach,
            visibility: visibility,
            birthday: birthday,
            height: height,
            gender: gender,
            profileImagePath: profileImagePath,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ProfilesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({appSettingsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (appSettingsRefs) db.appSettings],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (appSettingsRefs)
                    await $_getPrefetchedData<Profile, $ProfilesTable,
                            AppSetting>(
                        currentTable: table,
                        referencedTable:
                            $$ProfilesTableReferences._appSettingsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProfilesTableReferences(db, table, p0)
                                .appSettingsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ProfilesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProfilesTable,
    Profile,
    $$ProfilesTableFilterComposer,
    $$ProfilesTableOrderingComposer,
    $$ProfilesTableAnnotationComposer,
    $$ProfilesTableCreateCompanionBuilder,
    $$ProfilesTableUpdateCompanionBuilder,
    (Profile, $$ProfilesTableReferences),
    Profile,
    PrefetchHooks Function({bool appSettingsRefs})>;
typedef $$AppSettingsTableCreateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required String userId,
  Value<String> themeMode,
  Value<String> unitSystem,
  Value<int> targetCalories,
  Value<int> targetProtein,
  Value<int> targetCarbs,
  Value<int> targetFat,
  Value<int> targetWater,
  Value<int> targetSteps,
});
typedef $$AppSettingsTableUpdateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> userId,
  Value<String> themeMode,
  Value<String> unitSystem,
  Value<int> targetCalories,
  Value<int> targetProtein,
  Value<int> targetCarbs,
  Value<int> targetFat,
  Value<int> targetWater,
  Value<int> targetSteps,
});

final class $$AppSettingsTableReferences
    extends BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting> {
  $$AppSettingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProfilesTable _userIdTable(_$AppDatabase db) => db.profiles
      .createAlias($_aliasNameGenerator(db.appSettings.userId, db.profiles.id));

  $$ProfilesTableProcessedTableManager get userId {
    final $_column = $_itemColumn<String>('user_id')!;

    final manager = $$ProfilesTableTableManager($_db, $_db.profiles)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get themeMode => $composableBuilder(
      column: $table.themeMode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unitSystem => $composableBuilder(
      column: $table.unitSystem, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetCalories => $composableBuilder(
      column: $table.targetCalories,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetProtein => $composableBuilder(
      column: $table.targetProtein, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetCarbs => $composableBuilder(
      column: $table.targetCarbs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetFat => $composableBuilder(
      column: $table.targetFat, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetWater => $composableBuilder(
      column: $table.targetWater, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetSteps => $composableBuilder(
      column: $table.targetSteps, builder: (column) => ColumnFilters(column));

  $$ProfilesTableFilterComposer get userId {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.profiles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProfilesTableFilterComposer(
              $db: $db,
              $table: $db.profiles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get themeMode => $composableBuilder(
      column: $table.themeMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unitSystem => $composableBuilder(
      column: $table.unitSystem, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetCalories => $composableBuilder(
      column: $table.targetCalories,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetProtein => $composableBuilder(
      column: $table.targetProtein,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetCarbs => $composableBuilder(
      column: $table.targetCarbs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetFat => $composableBuilder(
      column: $table.targetFat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetWater => $composableBuilder(
      column: $table.targetWater, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetSteps => $composableBuilder(
      column: $table.targetSteps, builder: (column) => ColumnOrderings(column));

  $$ProfilesTableOrderingComposer get userId {
    final $$ProfilesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.profiles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProfilesTableOrderingComposer(
              $db: $db,
              $table: $db.profiles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<String> get unitSystem => $composableBuilder(
      column: $table.unitSystem, builder: (column) => column);

  GeneratedColumn<int> get targetCalories => $composableBuilder(
      column: $table.targetCalories, builder: (column) => column);

  GeneratedColumn<int> get targetProtein => $composableBuilder(
      column: $table.targetProtein, builder: (column) => column);

  GeneratedColumn<int> get targetCarbs => $composableBuilder(
      column: $table.targetCarbs, builder: (column) => column);

  GeneratedColumn<int> get targetFat =>
      $composableBuilder(column: $table.targetFat, builder: (column) => column);

  GeneratedColumn<int> get targetWater => $composableBuilder(
      column: $table.targetWater, builder: (column) => column);

  GeneratedColumn<int> get targetSteps => $composableBuilder(
      column: $table.targetSteps, builder: (column) => column);

  $$ProfilesTableAnnotationComposer get userId {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.profiles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProfilesTableAnnotationComposer(
              $db: $db,
              $table: $db.profiles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AppSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, $$AppSettingsTableReferences),
    AppSetting,
    PrefetchHooks Function({bool userId})> {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> themeMode = const Value.absent(),
            Value<String> unitSystem = const Value.absent(),
            Value<int> targetCalories = const Value.absent(),
            Value<int> targetProtein = const Value.absent(),
            Value<int> targetCarbs = const Value.absent(),
            Value<int> targetFat = const Value.absent(),
            Value<int> targetWater = const Value.absent(),
            Value<int> targetSteps = const Value.absent(),
          }) =>
              AppSettingsCompanion(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            userId: userId,
            themeMode: themeMode,
            unitSystem: unitSystem,
            targetCalories: targetCalories,
            targetProtein: targetProtein,
            targetCarbs: targetCarbs,
            targetFat: targetFat,
            targetWater: targetWater,
            targetSteps: targetSteps,
          ),
          createCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            required String userId,
            Value<String> themeMode = const Value.absent(),
            Value<String> unitSystem = const Value.absent(),
            Value<int> targetCalories = const Value.absent(),
            Value<int> targetProtein = const Value.absent(),
            Value<int> targetCarbs = const Value.absent(),
            Value<int> targetFat = const Value.absent(),
            Value<int> targetWater = const Value.absent(),
            Value<int> targetSteps = const Value.absent(),
          }) =>
              AppSettingsCompanion.insert(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            userId: userId,
            themeMode: themeMode,
            unitSystem: unitSystem,
            targetCalories: targetCalories,
            targetProtein: targetProtein,
            targetCarbs: targetCarbs,
            targetFat: targetFat,
            targetWater: targetWater,
            targetSteps: targetSteps,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AppSettingsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (userId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userId,
                    referencedTable:
                        $$AppSettingsTableReferences._userIdTable(db),
                    referencedColumn:
                        $$AppSettingsTableReferences._userIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$AppSettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, $$AppSettingsTableReferences),
    AppSetting,
    PrefetchHooks Function({bool userId})>;
typedef $$ExercisesTableCreateCompanionBuilder = ExercisesCompanion Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> createdBy,
  required String nameDe,
  required String nameEn,
  Value<String?> descriptionDe,
  Value<String?> descriptionEn,
  Value<String?> categoryName,
  Value<String?> imagePath,
  Value<String?> musclesPrimary,
  Value<String?> musclesSecondary,
  Value<bool> isCustom,
  Value<String> source,
});
typedef $$ExercisesTableUpdateCompanionBuilder = ExercisesCompanion Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> createdBy,
  Value<String> nameDe,
  Value<String> nameEn,
  Value<String?> descriptionDe,
  Value<String?> descriptionEn,
  Value<String?> categoryName,
  Value<String?> imagePath,
  Value<String?> musclesPrimary,
  Value<String?> musclesSecondary,
  Value<bool> isCustom,
  Value<String> source,
});

final class $$ExercisesTableReferences
    extends BaseReferences<_$AppDatabase, $ExercisesTable, Exercise> {
  $$ExercisesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RoutineExercisesTable, List<RoutineExercise>>
      _routineExercisesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.routineExercises,
              aliasName: $_aliasNameGenerator(
                  db.exercises.id, db.routineExercises.exerciseId));

  $$RoutineExercisesTableProcessedTableManager get routineExercisesRefs {
    final manager = $$RoutineExercisesTableTableManager(
            $_db, $_db.routineExercises)
        .filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_routineExercisesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$SetLogsTable, List<SetLog>> _setLogsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.setLogs,
          aliasName:
              $_aliasNameGenerator(db.exercises.id, db.setLogs.exerciseId));

  $$SetLogsTableProcessedTableManager get setLogsRefs {
    final manager = $$SetLogsTableTableManager($_db, $_db.setLogs)
        .filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_setLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdBy => $composableBuilder(
      column: $table.createdBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameDe => $composableBuilder(
      column: $table.nameDe, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameEn => $composableBuilder(
      column: $table.nameEn, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get descriptionDe => $composableBuilder(
      column: $table.descriptionDe, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get descriptionEn => $composableBuilder(
      column: $table.descriptionEn, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryName => $composableBuilder(
      column: $table.categoryName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get musclesPrimary => $composableBuilder(
      column: $table.musclesPrimary,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get musclesSecondary => $composableBuilder(
      column: $table.musclesSecondary,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCustom => $composableBuilder(
      column: $table.isCustom, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  Expression<bool> routineExercisesRefs(
      Expression<bool> Function($$RoutineExercisesTableFilterComposer f) f) {
    final $$RoutineExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.routineExercises,
        getReferencedColumn: (t) => t.exerciseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutineExercisesTableFilterComposer(
              $db: $db,
              $table: $db.routineExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> setLogsRefs(
      Expression<bool> Function($$SetLogsTableFilterComposer f) f) {
    final $$SetLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.setLogs,
        getReferencedColumn: (t) => t.exerciseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SetLogsTableFilterComposer(
              $db: $db,
              $table: $db.setLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdBy => $composableBuilder(
      column: $table.createdBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameDe => $composableBuilder(
      column: $table.nameDe, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameEn => $composableBuilder(
      column: $table.nameEn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get descriptionDe => $composableBuilder(
      column: $table.descriptionDe,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get descriptionEn => $composableBuilder(
      column: $table.descriptionEn,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryName => $composableBuilder(
      column: $table.categoryName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get musclesPrimary => $composableBuilder(
      column: $table.musclesPrimary,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get musclesSecondary => $composableBuilder(
      column: $table.musclesSecondary,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCustom => $composableBuilder(
      column: $table.isCustom, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));
}

class $$ExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get nameDe =>
      $composableBuilder(column: $table.nameDe, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get descriptionDe => $composableBuilder(
      column: $table.descriptionDe, builder: (column) => column);

  GeneratedColumn<String> get descriptionEn => $composableBuilder(
      column: $table.descriptionEn, builder: (column) => column);

  GeneratedColumn<String> get categoryName => $composableBuilder(
      column: $table.categoryName, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get musclesPrimary => $composableBuilder(
      column: $table.musclesPrimary, builder: (column) => column);

  GeneratedColumn<String> get musclesSecondary => $composableBuilder(
      column: $table.musclesSecondary, builder: (column) => column);

  GeneratedColumn<bool> get isCustom =>
      $composableBuilder(column: $table.isCustom, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  Expression<T> routineExercisesRefs<T extends Object>(
      Expression<T> Function($$RoutineExercisesTableAnnotationComposer a) f) {
    final $$RoutineExercisesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.routineExercises,
        getReferencedColumn: (t) => t.exerciseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutineExercisesTableAnnotationComposer(
              $db: $db,
              $table: $db.routineExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> setLogsRefs<T extends Object>(
      Expression<T> Function($$SetLogsTableAnnotationComposer a) f) {
    final $$SetLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.setLogs,
        getReferencedColumn: (t) => t.exerciseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SetLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.setLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ExercisesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExercisesTable,
    Exercise,
    $$ExercisesTableFilterComposer,
    $$ExercisesTableOrderingComposer,
    $$ExercisesTableAnnotationComposer,
    $$ExercisesTableCreateCompanionBuilder,
    $$ExercisesTableUpdateCompanionBuilder,
    (Exercise, $$ExercisesTableReferences),
    Exercise,
    PrefetchHooks Function({bool routineExercisesRefs, bool setLogsRefs})> {
  $$ExercisesTableTableManager(_$AppDatabase db, $ExercisesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String?> createdBy = const Value.absent(),
            Value<String> nameDe = const Value.absent(),
            Value<String> nameEn = const Value.absent(),
            Value<String?> descriptionDe = const Value.absent(),
            Value<String?> descriptionEn = const Value.absent(),
            Value<String?> categoryName = const Value.absent(),
            Value<String?> imagePath = const Value.absent(),
            Value<String?> musclesPrimary = const Value.absent(),
            Value<String?> musclesSecondary = const Value.absent(),
            Value<bool> isCustom = const Value.absent(),
            Value<String> source = const Value.absent(),
          }) =>
              ExercisesCompanion(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            createdBy: createdBy,
            nameDe: nameDe,
            nameEn: nameEn,
            descriptionDe: descriptionDe,
            descriptionEn: descriptionEn,
            categoryName: categoryName,
            imagePath: imagePath,
            musclesPrimary: musclesPrimary,
            musclesSecondary: musclesSecondary,
            isCustom: isCustom,
            source: source,
          ),
          createCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String?> createdBy = const Value.absent(),
            required String nameDe,
            required String nameEn,
            Value<String?> descriptionDe = const Value.absent(),
            Value<String?> descriptionEn = const Value.absent(),
            Value<String?> categoryName = const Value.absent(),
            Value<String?> imagePath = const Value.absent(),
            Value<String?> musclesPrimary = const Value.absent(),
            Value<String?> musclesSecondary = const Value.absent(),
            Value<bool> isCustom = const Value.absent(),
            Value<String> source = const Value.absent(),
          }) =>
              ExercisesCompanion.insert(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            createdBy: createdBy,
            nameDe: nameDe,
            nameEn: nameEn,
            descriptionDe: descriptionDe,
            descriptionEn: descriptionEn,
            categoryName: categoryName,
            imagePath: imagePath,
            musclesPrimary: musclesPrimary,
            musclesSecondary: musclesSecondary,
            isCustom: isCustom,
            source: source,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ExercisesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {routineExercisesRefs = false, setLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (routineExercisesRefs) db.routineExercises,
                if (setLogsRefs) db.setLogs
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (routineExercisesRefs)
                    await $_getPrefetchedData<Exercise, $ExercisesTable,
                            RoutineExercise>(
                        currentTable: table,
                        referencedTable: $$ExercisesTableReferences
                            ._routineExercisesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ExercisesTableReferences(db, table, p0)
                                .routineExercisesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.exerciseId == item.id),
                        typedResults: items),
                  if (setLogsRefs)
                    await $_getPrefetchedData<Exercise, $ExercisesTable,
                            SetLog>(
                        currentTable: table,
                        referencedTable:
                            $$ExercisesTableReferences._setLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ExercisesTableReferences(db, table, p0)
                                .setLogsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.exerciseId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ExercisesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ExercisesTable,
    Exercise,
    $$ExercisesTableFilterComposer,
    $$ExercisesTableOrderingComposer,
    $$ExercisesTableAnnotationComposer,
    $$ExercisesTableCreateCompanionBuilder,
    $$ExercisesTableUpdateCompanionBuilder,
    (Exercise, $$ExercisesTableReferences),
    Exercise,
    PrefetchHooks Function({bool routineExercisesRefs, bool setLogsRefs})>;
typedef $$RoutinesTableCreateCompanionBuilder = RoutinesCompanion Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> userId,
  required String name,
  Value<bool> isPublic,
});
typedef $$RoutinesTableUpdateCompanionBuilder = RoutinesCompanion Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> userId,
  Value<String> name,
  Value<bool> isPublic,
});

final class $$RoutinesTableReferences
    extends BaseReferences<_$AppDatabase, $RoutinesTable, Routine> {
  $$RoutinesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RoutineExercisesTable, List<RoutineExercise>>
      _routineExercisesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.routineExercises,
              aliasName: $_aliasNameGenerator(
                  db.routines.id, db.routineExercises.routineId));

  $$RoutineExercisesTableProcessedTableManager get routineExercisesRefs {
    final manager = $$RoutineExercisesTableTableManager(
            $_db, $_db.routineExercises)
        .filter((f) => f.routineId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_routineExercisesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$WorkoutLogsTable, List<WorkoutLog>>
      _workoutLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.workoutLogs,
          aliasName:
              $_aliasNameGenerator(db.routines.id, db.workoutLogs.routineId));

  $$WorkoutLogsTableProcessedTableManager get workoutLogsRefs {
    final manager = $$WorkoutLogsTableTableManager($_db, $_db.workoutLogs)
        .filter((f) => f.routineId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_workoutLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$RoutinesTableFilterComposer
    extends Composer<_$AppDatabase, $RoutinesTable> {
  $$RoutinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPublic => $composableBuilder(
      column: $table.isPublic, builder: (column) => ColumnFilters(column));

  Expression<bool> routineExercisesRefs(
      Expression<bool> Function($$RoutineExercisesTableFilterComposer f) f) {
    final $$RoutineExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.routineExercises,
        getReferencedColumn: (t) => t.routineId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutineExercisesTableFilterComposer(
              $db: $db,
              $table: $db.routineExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> workoutLogsRefs(
      Expression<bool> Function($$WorkoutLogsTableFilterComposer f) f) {
    final $$WorkoutLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutLogs,
        getReferencedColumn: (t) => t.routineId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutLogsTableFilterComposer(
              $db: $db,
              $table: $db.workoutLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$RoutinesTableOrderingComposer
    extends Composer<_$AppDatabase, $RoutinesTable> {
  $$RoutinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPublic => $composableBuilder(
      column: $table.isPublic, builder: (column) => ColumnOrderings(column));
}

class $$RoutinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoutinesTable> {
  $$RoutinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isPublic =>
      $composableBuilder(column: $table.isPublic, builder: (column) => column);

  Expression<T> routineExercisesRefs<T extends Object>(
      Expression<T> Function($$RoutineExercisesTableAnnotationComposer a) f) {
    final $$RoutineExercisesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.routineExercises,
        getReferencedColumn: (t) => t.routineId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutineExercisesTableAnnotationComposer(
              $db: $db,
              $table: $db.routineExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> workoutLogsRefs<T extends Object>(
      Expression<T> Function($$WorkoutLogsTableAnnotationComposer a) f) {
    final $$WorkoutLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutLogs,
        getReferencedColumn: (t) => t.routineId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$RoutinesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RoutinesTable,
    Routine,
    $$RoutinesTableFilterComposer,
    $$RoutinesTableOrderingComposer,
    $$RoutinesTableAnnotationComposer,
    $$RoutinesTableCreateCompanionBuilder,
    $$RoutinesTableUpdateCompanionBuilder,
    (Routine, $$RoutinesTableReferences),
    Routine,
    PrefetchHooks Function({bool routineExercisesRefs, bool workoutLogsRefs})> {
  $$RoutinesTableTableManager(_$AppDatabase db, $RoutinesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoutinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoutinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoutinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<bool> isPublic = const Value.absent(),
          }) =>
              RoutinesCompanion(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            userId: userId,
            name: name,
            isPublic: isPublic,
          ),
          createCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            required String name,
            Value<bool> isPublic = const Value.absent(),
          }) =>
              RoutinesCompanion.insert(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            userId: userId,
            name: name,
            isPublic: isPublic,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$RoutinesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {routineExercisesRefs = false, workoutLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (routineExercisesRefs) db.routineExercises,
                if (workoutLogsRefs) db.workoutLogs
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (routineExercisesRefs)
                    await $_getPrefetchedData<Routine, $RoutinesTable,
                            RoutineExercise>(
                        currentTable: table,
                        referencedTable: $$RoutinesTableReferences
                            ._routineExercisesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RoutinesTableReferences(db, table, p0)
                                .routineExercisesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.routineId == item.id),
                        typedResults: items),
                  if (workoutLogsRefs)
                    await $_getPrefetchedData<Routine, $RoutinesTable,
                            WorkoutLog>(
                        currentTable: table,
                        referencedTable:
                            $$RoutinesTableReferences._workoutLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RoutinesTableReferences(db, table, p0)
                                .workoutLogsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.routineId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$RoutinesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RoutinesTable,
    Routine,
    $$RoutinesTableFilterComposer,
    $$RoutinesTableOrderingComposer,
    $$RoutinesTableAnnotationComposer,
    $$RoutinesTableCreateCompanionBuilder,
    $$RoutinesTableUpdateCompanionBuilder,
    (Routine, $$RoutinesTableReferences),
    Routine,
    PrefetchHooks Function({bool routineExercisesRefs, bool workoutLogsRefs})>;
typedef $$RoutineExercisesTableCreateCompanionBuilder
    = RoutineExercisesCompanion Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required String routineId,
  required String exerciseId,
  required int orderIndex,
  Value<int?> pauseSeconds,
});
typedef $$RoutineExercisesTableUpdateCompanionBuilder
    = RoutineExercisesCompanion Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> routineId,
  Value<String> exerciseId,
  Value<int> orderIndex,
  Value<int?> pauseSeconds,
});

final class $$RoutineExercisesTableReferences extends BaseReferences<
    _$AppDatabase, $RoutineExercisesTable, RoutineExercise> {
  $$RoutineExercisesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $RoutinesTable _routineIdTable(_$AppDatabase db) =>
      db.routines.createAlias(
          $_aliasNameGenerator(db.routineExercises.routineId, db.routines.id));

  $$RoutinesTableProcessedTableManager get routineId {
    final $_column = $_itemColumn<String>('routine_id')!;

    final manager = $$RoutinesTableTableManager($_db, $_db.routines)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_routineIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias($_aliasNameGenerator(
          db.routineExercises.exerciseId, db.exercises.id));

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<String>('exercise_id')!;

    final manager = $$ExercisesTableTableManager($_db, $_db.exercises)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$RoutineSetTemplatesTable,
      List<RoutineSetTemplate>> _routineSetTemplatesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.routineSetTemplates,
          aliasName: $_aliasNameGenerator(db.routineExercises.id,
              db.routineSetTemplates.routineExerciseId));

  $$RoutineSetTemplatesTableProcessedTableManager get routineSetTemplatesRefs {
    final manager =
        $$RoutineSetTemplatesTableTableManager($_db, $_db.routineSetTemplates)
            .filter((f) =>
                f.routineExerciseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_routineSetTemplatesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$RoutineExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $RoutineExercisesTable> {
  $$RoutineExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pauseSeconds => $composableBuilder(
      column: $table.pauseSeconds, builder: (column) => ColumnFilters(column));

  $$RoutinesTableFilterComposer get routineId {
    final $$RoutinesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.routineId,
        referencedTable: $db.routines,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutinesTableFilterComposer(
              $db: $db,
              $table: $db.routines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableFilterComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> routineSetTemplatesRefs(
      Expression<bool> Function($$RoutineSetTemplatesTableFilterComposer f) f) {
    final $$RoutineSetTemplatesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.routineSetTemplates,
        getReferencedColumn: (t) => t.routineExerciseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutineSetTemplatesTableFilterComposer(
              $db: $db,
              $table: $db.routineSetTemplates,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$RoutineExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $RoutineExercisesTable> {
  $$RoutineExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pauseSeconds => $composableBuilder(
      column: $table.pauseSeconds,
      builder: (column) => ColumnOrderings(column));

  $$RoutinesTableOrderingComposer get routineId {
    final $$RoutinesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.routineId,
        referencedTable: $db.routines,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutinesTableOrderingComposer(
              $db: $db,
              $table: $db.routines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableOrderingComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RoutineExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoutineExercisesTable> {
  $$RoutineExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => column);

  GeneratedColumn<int> get pauseSeconds => $composableBuilder(
      column: $table.pauseSeconds, builder: (column) => column);

  $$RoutinesTableAnnotationComposer get routineId {
    final $$RoutinesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.routineId,
        referencedTable: $db.routines,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutinesTableAnnotationComposer(
              $db: $db,
              $table: $db.routines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableAnnotationComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> routineSetTemplatesRefs<T extends Object>(
      Expression<T> Function($$RoutineSetTemplatesTableAnnotationComposer a)
          f) {
    final $$RoutineSetTemplatesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.routineSetTemplates,
            getReferencedColumn: (t) => t.routineExerciseId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$RoutineSetTemplatesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.routineSetTemplates,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$RoutineExercisesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RoutineExercisesTable,
    RoutineExercise,
    $$RoutineExercisesTableFilterComposer,
    $$RoutineExercisesTableOrderingComposer,
    $$RoutineExercisesTableAnnotationComposer,
    $$RoutineExercisesTableCreateCompanionBuilder,
    $$RoutineExercisesTableUpdateCompanionBuilder,
    (RoutineExercise, $$RoutineExercisesTableReferences),
    RoutineExercise,
    PrefetchHooks Function(
        {bool routineId, bool exerciseId, bool routineSetTemplatesRefs})> {
  $$RoutineExercisesTableTableManager(
      _$AppDatabase db, $RoutineExercisesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoutineExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoutineExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoutineExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> routineId = const Value.absent(),
            Value<String> exerciseId = const Value.absent(),
            Value<int> orderIndex = const Value.absent(),
            Value<int?> pauseSeconds = const Value.absent(),
          }) =>
              RoutineExercisesCompanion(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            routineId: routineId,
            exerciseId: exerciseId,
            orderIndex: orderIndex,
            pauseSeconds: pauseSeconds,
          ),
          createCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            required String routineId,
            required String exerciseId,
            required int orderIndex,
            Value<int?> pauseSeconds = const Value.absent(),
          }) =>
              RoutineExercisesCompanion.insert(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            routineId: routineId,
            exerciseId: exerciseId,
            orderIndex: orderIndex,
            pauseSeconds: pauseSeconds,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$RoutineExercisesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {routineId = false,
              exerciseId = false,
              routineSetTemplatesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (routineSetTemplatesRefs) db.routineSetTemplates
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (routineId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.routineId,
                    referencedTable:
                        $$RoutineExercisesTableReferences._routineIdTable(db),
                    referencedColumn: $$RoutineExercisesTableReferences
                        ._routineIdTable(db)
                        .id,
                  ) as T;
                }
                if (exerciseId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.exerciseId,
                    referencedTable:
                        $$RoutineExercisesTableReferences._exerciseIdTable(db),
                    referencedColumn: $$RoutineExercisesTableReferences
                        ._exerciseIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (routineSetTemplatesRefs)
                    await $_getPrefetchedData<RoutineExercise,
                            $RoutineExercisesTable, RoutineSetTemplate>(
                        currentTable: table,
                        referencedTable: $$RoutineExercisesTableReferences
                            ._routineSetTemplatesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RoutineExercisesTableReferences(db, table, p0)
                                .routineSetTemplatesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.routineExerciseId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$RoutineExercisesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RoutineExercisesTable,
    RoutineExercise,
    $$RoutineExercisesTableFilterComposer,
    $$RoutineExercisesTableOrderingComposer,
    $$RoutineExercisesTableAnnotationComposer,
    $$RoutineExercisesTableCreateCompanionBuilder,
    $$RoutineExercisesTableUpdateCompanionBuilder,
    (RoutineExercise, $$RoutineExercisesTableReferences),
    RoutineExercise,
    PrefetchHooks Function(
        {bool routineId, bool exerciseId, bool routineSetTemplatesRefs})>;
typedef $$RoutineSetTemplatesTableCreateCompanionBuilder
    = RoutineSetTemplatesCompanion Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required String routineExerciseId,
  Value<String> setType,
  Value<String?> targetReps,
  Value<double?> targetWeight,
  Value<int?> targetRir,
});
typedef $$RoutineSetTemplatesTableUpdateCompanionBuilder
    = RoutineSetTemplatesCompanion Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> routineExerciseId,
  Value<String> setType,
  Value<String?> targetReps,
  Value<double?> targetWeight,
  Value<int?> targetRir,
});

final class $$RoutineSetTemplatesTableReferences extends BaseReferences<
    _$AppDatabase, $RoutineSetTemplatesTable, RoutineSetTemplate> {
  $$RoutineSetTemplatesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $RoutineExercisesTable _routineExerciseIdTable(_$AppDatabase db) =>
      db.routineExercises.createAlias($_aliasNameGenerator(
          db.routineSetTemplates.routineExerciseId, db.routineExercises.id));

  $$RoutineExercisesTableProcessedTableManager get routineExerciseId {
    final $_column = $_itemColumn<String>('routine_exercise_id')!;

    final manager =
        $$RoutineExercisesTableTableManager($_db, $_db.routineExercises)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_routineExerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$RoutineSetTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $RoutineSetTemplatesTable> {
  $$RoutineSetTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get setType => $composableBuilder(
      column: $table.setType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get targetReps => $composableBuilder(
      column: $table.targetReps, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get targetWeight => $composableBuilder(
      column: $table.targetWeight, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetRir => $composableBuilder(
      column: $table.targetRir, builder: (column) => ColumnFilters(column));

  $$RoutineExercisesTableFilterComposer get routineExerciseId {
    final $$RoutineExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.routineExerciseId,
        referencedTable: $db.routineExercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutineExercisesTableFilterComposer(
              $db: $db,
              $table: $db.routineExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RoutineSetTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $RoutineSetTemplatesTable> {
  $$RoutineSetTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get setType => $composableBuilder(
      column: $table.setType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get targetReps => $composableBuilder(
      column: $table.targetReps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get targetWeight => $composableBuilder(
      column: $table.targetWeight,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetRir => $composableBuilder(
      column: $table.targetRir, builder: (column) => ColumnOrderings(column));

  $$RoutineExercisesTableOrderingComposer get routineExerciseId {
    final $$RoutineExercisesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.routineExerciseId,
        referencedTable: $db.routineExercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutineExercisesTableOrderingComposer(
              $db: $db,
              $table: $db.routineExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RoutineSetTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoutineSetTemplatesTable> {
  $$RoutineSetTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get setType =>
      $composableBuilder(column: $table.setType, builder: (column) => column);

  GeneratedColumn<String> get targetReps => $composableBuilder(
      column: $table.targetReps, builder: (column) => column);

  GeneratedColumn<double> get targetWeight => $composableBuilder(
      column: $table.targetWeight, builder: (column) => column);

  GeneratedColumn<int> get targetRir =>
      $composableBuilder(column: $table.targetRir, builder: (column) => column);

  $$RoutineExercisesTableAnnotationComposer get routineExerciseId {
    final $$RoutineExercisesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.routineExerciseId,
        referencedTable: $db.routineExercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutineExercisesTableAnnotationComposer(
              $db: $db,
              $table: $db.routineExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RoutineSetTemplatesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RoutineSetTemplatesTable,
    RoutineSetTemplate,
    $$RoutineSetTemplatesTableFilterComposer,
    $$RoutineSetTemplatesTableOrderingComposer,
    $$RoutineSetTemplatesTableAnnotationComposer,
    $$RoutineSetTemplatesTableCreateCompanionBuilder,
    $$RoutineSetTemplatesTableUpdateCompanionBuilder,
    (RoutineSetTemplate, $$RoutineSetTemplatesTableReferences),
    RoutineSetTemplate,
    PrefetchHooks Function({bool routineExerciseId})> {
  $$RoutineSetTemplatesTableTableManager(
      _$AppDatabase db, $RoutineSetTemplatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoutineSetTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoutineSetTemplatesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoutineSetTemplatesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> routineExerciseId = const Value.absent(),
            Value<String> setType = const Value.absent(),
            Value<String?> targetReps = const Value.absent(),
            Value<double?> targetWeight = const Value.absent(),
            Value<int?> targetRir = const Value.absent(),
          }) =>
              RoutineSetTemplatesCompanion(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            routineExerciseId: routineExerciseId,
            setType: setType,
            targetReps: targetReps,
            targetWeight: targetWeight,
            targetRir: targetRir,
          ),
          createCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            required String routineExerciseId,
            Value<String> setType = const Value.absent(),
            Value<String?> targetReps = const Value.absent(),
            Value<double?> targetWeight = const Value.absent(),
            Value<int?> targetRir = const Value.absent(),
          }) =>
              RoutineSetTemplatesCompanion.insert(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            routineExerciseId: routineExerciseId,
            setType: setType,
            targetReps: targetReps,
            targetWeight: targetWeight,
            targetRir: targetRir,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$RoutineSetTemplatesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({routineExerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (routineExerciseId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.routineExerciseId,
                    referencedTable: $$RoutineSetTemplatesTableReferences
                        ._routineExerciseIdTable(db),
                    referencedColumn: $$RoutineSetTemplatesTableReferences
                        ._routineExerciseIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$RoutineSetTemplatesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RoutineSetTemplatesTable,
    RoutineSetTemplate,
    $$RoutineSetTemplatesTableFilterComposer,
    $$RoutineSetTemplatesTableOrderingComposer,
    $$RoutineSetTemplatesTableAnnotationComposer,
    $$RoutineSetTemplatesTableCreateCompanionBuilder,
    $$RoutineSetTemplatesTableUpdateCompanionBuilder,
    (RoutineSetTemplate, $$RoutineSetTemplatesTableReferences),
    RoutineSetTemplate,
    PrefetchHooks Function({bool routineExerciseId})>;
typedef $$WorkoutLogsTableCreateCompanionBuilder = WorkoutLogsCompanion
    Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> userId,
  Value<String?> routineId,
  Value<String?> routineNameSnapshot,
  required DateTime startTime,
  Value<DateTime?> endTime,
  Value<String> status,
  Value<String> visibility,
  Value<String?> notes,
});
typedef $$WorkoutLogsTableUpdateCompanionBuilder = WorkoutLogsCompanion
    Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> userId,
  Value<String?> routineId,
  Value<String?> routineNameSnapshot,
  Value<DateTime> startTime,
  Value<DateTime?> endTime,
  Value<String> status,
  Value<String> visibility,
  Value<String?> notes,
});

final class $$WorkoutLogsTableReferences
    extends BaseReferences<_$AppDatabase, $WorkoutLogsTable, WorkoutLog> {
  $$WorkoutLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RoutinesTable _routineIdTable(_$AppDatabase db) =>
      db.routines.createAlias(
          $_aliasNameGenerator(db.workoutLogs.routineId, db.routines.id));

  $$RoutinesTableProcessedTableManager? get routineId {
    final $_column = $_itemColumn<String>('routine_id');
    if ($_column == null) return null;
    final manager = $$RoutinesTableTableManager($_db, $_db.routines)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_routineIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$SetLogsTable, List<SetLog>> _setLogsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.setLogs,
          aliasName:
              $_aliasNameGenerator(db.workoutLogs.id, db.setLogs.workoutLogId));

  $$SetLogsTableProcessedTableManager get setLogsRefs {
    final manager = $$SetLogsTableTableManager($_db, $_db.setLogs).filter(
        (f) => f.workoutLogId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_setLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$CardioActivitiesTable, List<CardioActivity>>
      _cardioActivitiesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.cardioActivities,
              aliasName: $_aliasNameGenerator(
                  db.workoutLogs.id, db.cardioActivities.workoutLogId));

  $$CardioActivitiesTableProcessedTableManager get cardioActivitiesRefs {
    final manager =
        $$CardioActivitiesTableTableManager($_db, $_db.cardioActivities).filter(
            (f) => f.workoutLogId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_cardioActivitiesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$WorkoutLogsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutLogsTable> {
  $$WorkoutLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get routineNameSnapshot => $composableBuilder(
      column: $table.routineNameSnapshot,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get visibility => $composableBuilder(
      column: $table.visibility, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  $$RoutinesTableFilterComposer get routineId {
    final $$RoutinesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.routineId,
        referencedTable: $db.routines,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutinesTableFilterComposer(
              $db: $db,
              $table: $db.routines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> setLogsRefs(
      Expression<bool> Function($$SetLogsTableFilterComposer f) f) {
    final $$SetLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.setLogs,
        getReferencedColumn: (t) => t.workoutLogId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SetLogsTableFilterComposer(
              $db: $db,
              $table: $db.setLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> cardioActivitiesRefs(
      Expression<bool> Function($$CardioActivitiesTableFilterComposer f) f) {
    final $$CardioActivitiesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cardioActivities,
        getReferencedColumn: (t) => t.workoutLogId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardioActivitiesTableFilterComposer(
              $db: $db,
              $table: $db.cardioActivities,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WorkoutLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutLogsTable> {
  $$WorkoutLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get routineNameSnapshot => $composableBuilder(
      column: $table.routineNameSnapshot,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get visibility => $composableBuilder(
      column: $table.visibility, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  $$RoutinesTableOrderingComposer get routineId {
    final $$RoutinesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.routineId,
        referencedTable: $db.routines,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutinesTableOrderingComposer(
              $db: $db,
              $table: $db.routines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkoutLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutLogsTable> {
  $$WorkoutLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get routineNameSnapshot => $composableBuilder(
      column: $table.routineNameSnapshot, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get visibility => $composableBuilder(
      column: $table.visibility, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$RoutinesTableAnnotationComposer get routineId {
    final $$RoutinesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.routineId,
        referencedTable: $db.routines,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutinesTableAnnotationComposer(
              $db: $db,
              $table: $db.routines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> setLogsRefs<T extends Object>(
      Expression<T> Function($$SetLogsTableAnnotationComposer a) f) {
    final $$SetLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.setLogs,
        getReferencedColumn: (t) => t.workoutLogId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SetLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.setLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> cardioActivitiesRefs<T extends Object>(
      Expression<T> Function($$CardioActivitiesTableAnnotationComposer a) f) {
    final $$CardioActivitiesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cardioActivities,
        getReferencedColumn: (t) => t.workoutLogId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardioActivitiesTableAnnotationComposer(
              $db: $db,
              $table: $db.cardioActivities,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WorkoutLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WorkoutLogsTable,
    WorkoutLog,
    $$WorkoutLogsTableFilterComposer,
    $$WorkoutLogsTableOrderingComposer,
    $$WorkoutLogsTableAnnotationComposer,
    $$WorkoutLogsTableCreateCompanionBuilder,
    $$WorkoutLogsTableUpdateCompanionBuilder,
    (WorkoutLog, $$WorkoutLogsTableReferences),
    WorkoutLog,
    PrefetchHooks Function(
        {bool routineId, bool setLogsRefs, bool cardioActivitiesRefs})> {
  $$WorkoutLogsTableTableManager(_$AppDatabase db, $WorkoutLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> routineId = const Value.absent(),
            Value<String?> routineNameSnapshot = const Value.absent(),
            Value<DateTime> startTime = const Value.absent(),
            Value<DateTime?> endTime = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> visibility = const Value.absent(),
            Value<String?> notes = const Value.absent(),
          }) =>
              WorkoutLogsCompanion(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            userId: userId,
            routineId: routineId,
            routineNameSnapshot: routineNameSnapshot,
            startTime: startTime,
            endTime: endTime,
            status: status,
            visibility: visibility,
            notes: notes,
          ),
          createCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> routineId = const Value.absent(),
            Value<String?> routineNameSnapshot = const Value.absent(),
            required DateTime startTime,
            Value<DateTime?> endTime = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> visibility = const Value.absent(),
            Value<String?> notes = const Value.absent(),
          }) =>
              WorkoutLogsCompanion.insert(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            userId: userId,
            routineId: routineId,
            routineNameSnapshot: routineNameSnapshot,
            startTime: startTime,
            endTime: endTime,
            status: status,
            visibility: visibility,
            notes: notes,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$WorkoutLogsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {routineId = false,
              setLogsRefs = false,
              cardioActivitiesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (setLogsRefs) db.setLogs,
                if (cardioActivitiesRefs) db.cardioActivities
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (routineId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.routineId,
                    referencedTable:
                        $$WorkoutLogsTableReferences._routineIdTable(db),
                    referencedColumn:
                        $$WorkoutLogsTableReferences._routineIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (setLogsRefs)
                    await $_getPrefetchedData<WorkoutLog, $WorkoutLogsTable,
                            SetLog>(
                        currentTable: table,
                        referencedTable:
                            $$WorkoutLogsTableReferences._setLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WorkoutLogsTableReferences(db, table, p0)
                                .setLogsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.workoutLogId == item.id),
                        typedResults: items),
                  if (cardioActivitiesRefs)
                    await $_getPrefetchedData<WorkoutLog, $WorkoutLogsTable,
                            CardioActivity>(
                        currentTable: table,
                        referencedTable: $$WorkoutLogsTableReferences
                            ._cardioActivitiesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WorkoutLogsTableReferences(db, table, p0)
                                .cardioActivitiesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.workoutLogId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$WorkoutLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WorkoutLogsTable,
    WorkoutLog,
    $$WorkoutLogsTableFilterComposer,
    $$WorkoutLogsTableOrderingComposer,
    $$WorkoutLogsTableAnnotationComposer,
    $$WorkoutLogsTableCreateCompanionBuilder,
    $$WorkoutLogsTableUpdateCompanionBuilder,
    (WorkoutLog, $$WorkoutLogsTableReferences),
    WorkoutLog,
    PrefetchHooks Function(
        {bool routineId, bool setLogsRefs, bool cardioActivitiesRefs})>;
typedef $$SetLogsTableCreateCompanionBuilder = SetLogsCompanion Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required String workoutLogId,
  Value<String?> exerciseId,
  Value<String?> exerciseNameSnapshot,
  Value<double?> weight,
  Value<int?> reps,
  Value<int?> rpe,
  Value<int?> rir,
  Value<String> setType,
  Value<int?> restTimeSeconds,
  Value<bool> isCompleted,
  Value<int> logOrder,
  Value<double?> distance,
  Value<int?> durationSeconds,
  Value<String?> notes,
});
typedef $$SetLogsTableUpdateCompanionBuilder = SetLogsCompanion Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> workoutLogId,
  Value<String?> exerciseId,
  Value<String?> exerciseNameSnapshot,
  Value<double?> weight,
  Value<int?> reps,
  Value<int?> rpe,
  Value<int?> rir,
  Value<String> setType,
  Value<int?> restTimeSeconds,
  Value<bool> isCompleted,
  Value<int> logOrder,
  Value<double?> distance,
  Value<int?> durationSeconds,
  Value<String?> notes,
});

final class $$SetLogsTableReferences
    extends BaseReferences<_$AppDatabase, $SetLogsTable, SetLog> {
  $$SetLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkoutLogsTable _workoutLogIdTable(_$AppDatabase db) =>
      db.workoutLogs.createAlias(
          $_aliasNameGenerator(db.setLogs.workoutLogId, db.workoutLogs.id));

  $$WorkoutLogsTableProcessedTableManager get workoutLogId {
    final $_column = $_itemColumn<String>('workout_log_id')!;

    final manager = $$WorkoutLogsTableTableManager($_db, $_db.workoutLogs)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workoutLogIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias(
          $_aliasNameGenerator(db.setLogs.exerciseId, db.exercises.id));

  $$ExercisesTableProcessedTableManager? get exerciseId {
    final $_column = $_itemColumn<String>('exercise_id');
    if ($_column == null) return null;
    final manager = $$ExercisesTableTableManager($_db, $_db.exercises)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$SetLogsTableFilterComposer
    extends Composer<_$AppDatabase, $SetLogsTable> {
  $$SetLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exerciseNameSnapshot => $composableBuilder(
      column: $table.exerciseNameSnapshot,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reps => $composableBuilder(
      column: $table.reps, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rpe => $composableBuilder(
      column: $table.rpe, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rir => $composableBuilder(
      column: $table.rir, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get setType => $composableBuilder(
      column: $table.setType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get restTimeSeconds => $composableBuilder(
      column: $table.restTimeSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get logOrder => $composableBuilder(
      column: $table.logOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get distance => $composableBuilder(
      column: $table.distance, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  $$WorkoutLogsTableFilterComposer get workoutLogId {
    final $$WorkoutLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workoutLogId,
        referencedTable: $db.workoutLogs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutLogsTableFilterComposer(
              $db: $db,
              $table: $db.workoutLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableFilterComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SetLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $SetLogsTable> {
  $$SetLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exerciseNameSnapshot => $composableBuilder(
      column: $table.exerciseNameSnapshot,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reps => $composableBuilder(
      column: $table.reps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rpe => $composableBuilder(
      column: $table.rpe, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rir => $composableBuilder(
      column: $table.rir, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get setType => $composableBuilder(
      column: $table.setType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get restTimeSeconds => $composableBuilder(
      column: $table.restTimeSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get logOrder => $composableBuilder(
      column: $table.logOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get distance => $composableBuilder(
      column: $table.distance, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  $$WorkoutLogsTableOrderingComposer get workoutLogId {
    final $$WorkoutLogsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workoutLogId,
        referencedTable: $db.workoutLogs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutLogsTableOrderingComposer(
              $db: $db,
              $table: $db.workoutLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableOrderingComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SetLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SetLogsTable> {
  $$SetLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get exerciseNameSnapshot => $composableBuilder(
      column: $table.exerciseNameSnapshot, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get rpe =>
      $composableBuilder(column: $table.rpe, builder: (column) => column);

  GeneratedColumn<int> get rir =>
      $composableBuilder(column: $table.rir, builder: (column) => column);

  GeneratedColumn<String> get setType =>
      $composableBuilder(column: $table.setType, builder: (column) => column);

  GeneratedColumn<int> get restTimeSeconds => $composableBuilder(
      column: $table.restTimeSeconds, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => column);

  GeneratedColumn<int> get logOrder =>
      $composableBuilder(column: $table.logOrder, builder: (column) => column);

  GeneratedColumn<double> get distance =>
      $composableBuilder(column: $table.distance, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$WorkoutLogsTableAnnotationComposer get workoutLogId {
    final $$WorkoutLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workoutLogId,
        referencedTable: $db.workoutLogs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableAnnotationComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SetLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SetLogsTable,
    SetLog,
    $$SetLogsTableFilterComposer,
    $$SetLogsTableOrderingComposer,
    $$SetLogsTableAnnotationComposer,
    $$SetLogsTableCreateCompanionBuilder,
    $$SetLogsTableUpdateCompanionBuilder,
    (SetLog, $$SetLogsTableReferences),
    SetLog,
    PrefetchHooks Function({bool workoutLogId, bool exerciseId})> {
  $$SetLogsTableTableManager(_$AppDatabase db, $SetLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SetLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SetLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SetLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> workoutLogId = const Value.absent(),
            Value<String?> exerciseId = const Value.absent(),
            Value<String?> exerciseNameSnapshot = const Value.absent(),
            Value<double?> weight = const Value.absent(),
            Value<int?> reps = const Value.absent(),
            Value<int?> rpe = const Value.absent(),
            Value<int?> rir = const Value.absent(),
            Value<String> setType = const Value.absent(),
            Value<int?> restTimeSeconds = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            Value<int> logOrder = const Value.absent(),
            Value<double?> distance = const Value.absent(),
            Value<int?> durationSeconds = const Value.absent(),
            Value<String?> notes = const Value.absent(),
          }) =>
              SetLogsCompanion(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            workoutLogId: workoutLogId,
            exerciseId: exerciseId,
            exerciseNameSnapshot: exerciseNameSnapshot,
            weight: weight,
            reps: reps,
            rpe: rpe,
            rir: rir,
            setType: setType,
            restTimeSeconds: restTimeSeconds,
            isCompleted: isCompleted,
            logOrder: logOrder,
            distance: distance,
            durationSeconds: durationSeconds,
            notes: notes,
          ),
          createCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            required String workoutLogId,
            Value<String?> exerciseId = const Value.absent(),
            Value<String?> exerciseNameSnapshot = const Value.absent(),
            Value<double?> weight = const Value.absent(),
            Value<int?> reps = const Value.absent(),
            Value<int?> rpe = const Value.absent(),
            Value<int?> rir = const Value.absent(),
            Value<String> setType = const Value.absent(),
            Value<int?> restTimeSeconds = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            Value<int> logOrder = const Value.absent(),
            Value<double?> distance = const Value.absent(),
            Value<int?> durationSeconds = const Value.absent(),
            Value<String?> notes = const Value.absent(),
          }) =>
              SetLogsCompanion.insert(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            workoutLogId: workoutLogId,
            exerciseId: exerciseId,
            exerciseNameSnapshot: exerciseNameSnapshot,
            weight: weight,
            reps: reps,
            rpe: rpe,
            rir: rir,
            setType: setType,
            restTimeSeconds: restTimeSeconds,
            isCompleted: isCompleted,
            logOrder: logOrder,
            distance: distance,
            durationSeconds: durationSeconds,
            notes: notes,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$SetLogsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({workoutLogId = false, exerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (workoutLogId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.workoutLogId,
                    referencedTable:
                        $$SetLogsTableReferences._workoutLogIdTable(db),
                    referencedColumn:
                        $$SetLogsTableReferences._workoutLogIdTable(db).id,
                  ) as T;
                }
                if (exerciseId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.exerciseId,
                    referencedTable:
                        $$SetLogsTableReferences._exerciseIdTable(db),
                    referencedColumn:
                        $$SetLogsTableReferences._exerciseIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$SetLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SetLogsTable,
    SetLog,
    $$SetLogsTableFilterComposer,
    $$SetLogsTableOrderingComposer,
    $$SetLogsTableAnnotationComposer,
    $$SetLogsTableCreateCompanionBuilder,
    $$SetLogsTableUpdateCompanionBuilder,
    (SetLog, $$SetLogsTableReferences),
    SetLog,
    PrefetchHooks Function({bool workoutLogId, bool exerciseId})>;
typedef $$CardioActivitiesTableCreateCompanionBuilder
    = CardioActivitiesCompanion Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required String workoutLogId,
  required String type,
  Value<double?> distance,
  Value<int?> durationSeconds,
  Value<int?> kcal,
  Value<String?> source,
});
typedef $$CardioActivitiesTableUpdateCompanionBuilder
    = CardioActivitiesCompanion Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> workoutLogId,
  Value<String> type,
  Value<double?> distance,
  Value<int?> durationSeconds,
  Value<int?> kcal,
  Value<String?> source,
});

final class $$CardioActivitiesTableReferences extends BaseReferences<
    _$AppDatabase, $CardioActivitiesTable, CardioActivity> {
  $$CardioActivitiesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $WorkoutLogsTable _workoutLogIdTable(_$AppDatabase db) =>
      db.workoutLogs.createAlias($_aliasNameGenerator(
          db.cardioActivities.workoutLogId, db.workoutLogs.id));

  $$WorkoutLogsTableProcessedTableManager get workoutLogId {
    final $_column = $_itemColumn<String>('workout_log_id')!;

    final manager = $$WorkoutLogsTableTableManager($_db, $_db.workoutLogs)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workoutLogIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$CardioSamplesTable, List<CardioSample>>
      _cardioSamplesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.cardioSamples,
              aliasName: $_aliasNameGenerator(
                  db.cardioActivities.id, db.cardioSamples.cardioActivityId));

  $$CardioSamplesTableProcessedTableManager get cardioSamplesRefs {
    final manager = $$CardioSamplesTableTableManager($_db, $_db.cardioSamples)
        .filter((f) =>
            f.cardioActivityId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cardioSamplesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CardioActivitiesTableFilterComposer
    extends Composer<_$AppDatabase, $CardioActivitiesTable> {
  $$CardioActivitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get distance => $composableBuilder(
      column: $table.distance, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get kcal => $composableBuilder(
      column: $table.kcal, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  $$WorkoutLogsTableFilterComposer get workoutLogId {
    final $$WorkoutLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workoutLogId,
        referencedTable: $db.workoutLogs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutLogsTableFilterComposer(
              $db: $db,
              $table: $db.workoutLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> cardioSamplesRefs(
      Expression<bool> Function($$CardioSamplesTableFilterComposer f) f) {
    final $$CardioSamplesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cardioSamples,
        getReferencedColumn: (t) => t.cardioActivityId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardioSamplesTableFilterComposer(
              $db: $db,
              $table: $db.cardioSamples,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CardioActivitiesTableOrderingComposer
    extends Composer<_$AppDatabase, $CardioActivitiesTable> {
  $$CardioActivitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get distance => $composableBuilder(
      column: $table.distance, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get kcal => $composableBuilder(
      column: $table.kcal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  $$WorkoutLogsTableOrderingComposer get workoutLogId {
    final $$WorkoutLogsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workoutLogId,
        referencedTable: $db.workoutLogs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutLogsTableOrderingComposer(
              $db: $db,
              $table: $db.workoutLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CardioActivitiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CardioActivitiesTable> {
  $$CardioActivitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get distance =>
      $composableBuilder(column: $table.distance, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds, builder: (column) => column);

  GeneratedColumn<int> get kcal =>
      $composableBuilder(column: $table.kcal, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  $$WorkoutLogsTableAnnotationComposer get workoutLogId {
    final $$WorkoutLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workoutLogId,
        referencedTable: $db.workoutLogs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> cardioSamplesRefs<T extends Object>(
      Expression<T> Function($$CardioSamplesTableAnnotationComposer a) f) {
    final $$CardioSamplesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cardioSamples,
        getReferencedColumn: (t) => t.cardioActivityId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardioSamplesTableAnnotationComposer(
              $db: $db,
              $table: $db.cardioSamples,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CardioActivitiesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CardioActivitiesTable,
    CardioActivity,
    $$CardioActivitiesTableFilterComposer,
    $$CardioActivitiesTableOrderingComposer,
    $$CardioActivitiesTableAnnotationComposer,
    $$CardioActivitiesTableCreateCompanionBuilder,
    $$CardioActivitiesTableUpdateCompanionBuilder,
    (CardioActivity, $$CardioActivitiesTableReferences),
    CardioActivity,
    PrefetchHooks Function({bool workoutLogId, bool cardioSamplesRefs})> {
  $$CardioActivitiesTableTableManager(
      _$AppDatabase db, $CardioActivitiesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardioActivitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardioActivitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardioActivitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> workoutLogId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<double?> distance = const Value.absent(),
            Value<int?> durationSeconds = const Value.absent(),
            Value<int?> kcal = const Value.absent(),
            Value<String?> source = const Value.absent(),
          }) =>
              CardioActivitiesCompanion(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            workoutLogId: workoutLogId,
            type: type,
            distance: distance,
            durationSeconds: durationSeconds,
            kcal: kcal,
            source: source,
          ),
          createCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            required String workoutLogId,
            required String type,
            Value<double?> distance = const Value.absent(),
            Value<int?> durationSeconds = const Value.absent(),
            Value<int?> kcal = const Value.absent(),
            Value<String?> source = const Value.absent(),
          }) =>
              CardioActivitiesCompanion.insert(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            workoutLogId: workoutLogId,
            type: type,
            distance: distance,
            durationSeconds: durationSeconds,
            kcal: kcal,
            source: source,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CardioActivitiesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {workoutLogId = false, cardioSamplesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (cardioSamplesRefs) db.cardioSamples
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (workoutLogId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.workoutLogId,
                    referencedTable: $$CardioActivitiesTableReferences
                        ._workoutLogIdTable(db),
                    referencedColumn: $$CardioActivitiesTableReferences
                        ._workoutLogIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (cardioSamplesRefs)
                    await $_getPrefetchedData<CardioActivity,
                            $CardioActivitiesTable, CardioSample>(
                        currentTable: table,
                        referencedTable: $$CardioActivitiesTableReferences
                            ._cardioSamplesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CardioActivitiesTableReferences(db, table, p0)
                                .cardioSamplesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.cardioActivityId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CardioActivitiesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CardioActivitiesTable,
    CardioActivity,
    $$CardioActivitiesTableFilterComposer,
    $$CardioActivitiesTableOrderingComposer,
    $$CardioActivitiesTableAnnotationComposer,
    $$CardioActivitiesTableCreateCompanionBuilder,
    $$CardioActivitiesTableUpdateCompanionBuilder,
    (CardioActivity, $$CardioActivitiesTableReferences),
    CardioActivity,
    PrefetchHooks Function({bool workoutLogId, bool cardioSamplesRefs})>;
typedef $$CardioSamplesTableCreateCompanionBuilder = CardioSamplesCompanion
    Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required String cardioActivityId,
  required String dataType,
  required String dataJson,
});
typedef $$CardioSamplesTableUpdateCompanionBuilder = CardioSamplesCompanion
    Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> cardioActivityId,
  Value<String> dataType,
  Value<String> dataJson,
});

final class $$CardioSamplesTableReferences
    extends BaseReferences<_$AppDatabase, $CardioSamplesTable, CardioSample> {
  $$CardioSamplesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $CardioActivitiesTable _cardioActivityIdTable(_$AppDatabase db) =>
      db.cardioActivities.createAlias($_aliasNameGenerator(
          db.cardioSamples.cardioActivityId, db.cardioActivities.id));

  $$CardioActivitiesTableProcessedTableManager get cardioActivityId {
    final $_column = $_itemColumn<String>('cardio_activity_id')!;

    final manager =
        $$CardioActivitiesTableTableManager($_db, $_db.cardioActivities)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cardioActivityIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$CardioSamplesTableFilterComposer
    extends Composer<_$AppDatabase, $CardioSamplesTable> {
  $$CardioSamplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dataType => $composableBuilder(
      column: $table.dataType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dataJson => $composableBuilder(
      column: $table.dataJson, builder: (column) => ColumnFilters(column));

  $$CardioActivitiesTableFilterComposer get cardioActivityId {
    final $$CardioActivitiesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cardioActivityId,
        referencedTable: $db.cardioActivities,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardioActivitiesTableFilterComposer(
              $db: $db,
              $table: $db.cardioActivities,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CardioSamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $CardioSamplesTable> {
  $$CardioSamplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dataType => $composableBuilder(
      column: $table.dataType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dataJson => $composableBuilder(
      column: $table.dataJson, builder: (column) => ColumnOrderings(column));

  $$CardioActivitiesTableOrderingComposer get cardioActivityId {
    final $$CardioActivitiesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cardioActivityId,
        referencedTable: $db.cardioActivities,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardioActivitiesTableOrderingComposer(
              $db: $db,
              $table: $db.cardioActivities,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CardioSamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CardioSamplesTable> {
  $$CardioSamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get dataType =>
      $composableBuilder(column: $table.dataType, builder: (column) => column);

  GeneratedColumn<String> get dataJson =>
      $composableBuilder(column: $table.dataJson, builder: (column) => column);

  $$CardioActivitiesTableAnnotationComposer get cardioActivityId {
    final $$CardioActivitiesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cardioActivityId,
        referencedTable: $db.cardioActivities,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardioActivitiesTableAnnotationComposer(
              $db: $db,
              $table: $db.cardioActivities,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CardioSamplesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CardioSamplesTable,
    CardioSample,
    $$CardioSamplesTableFilterComposer,
    $$CardioSamplesTableOrderingComposer,
    $$CardioSamplesTableAnnotationComposer,
    $$CardioSamplesTableCreateCompanionBuilder,
    $$CardioSamplesTableUpdateCompanionBuilder,
    (CardioSample, $$CardioSamplesTableReferences),
    CardioSample,
    PrefetchHooks Function({bool cardioActivityId})> {
  $$CardioSamplesTableTableManager(_$AppDatabase db, $CardioSamplesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardioSamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardioSamplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardioSamplesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> cardioActivityId = const Value.absent(),
            Value<String> dataType = const Value.absent(),
            Value<String> dataJson = const Value.absent(),
          }) =>
              CardioSamplesCompanion(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            cardioActivityId: cardioActivityId,
            dataType: dataType,
            dataJson: dataJson,
          ),
          createCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            required String cardioActivityId,
            required String dataType,
            required String dataJson,
          }) =>
              CardioSamplesCompanion.insert(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            cardioActivityId: cardioActivityId,
            dataType: dataType,
            dataJson: dataJson,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CardioSamplesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({cardioActivityId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (cardioActivityId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.cardioActivityId,
                    referencedTable: $$CardioSamplesTableReferences
                        ._cardioActivityIdTable(db),
                    referencedColumn: $$CardioSamplesTableReferences
                        ._cardioActivityIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$CardioSamplesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CardioSamplesTable,
    CardioSample,
    $$CardioSamplesTableFilterComposer,
    $$CardioSamplesTableOrderingComposer,
    $$CardioSamplesTableAnnotationComposer,
    $$CardioSamplesTableCreateCompanionBuilder,
    $$CardioSamplesTableUpdateCompanionBuilder,
    (CardioSample, $$CardioSamplesTableReferences),
    CardioSample,
    PrefetchHooks Function({bool cardioActivityId})>;
typedef $$ProductsTableCreateCompanionBuilder = ProductsCompanion Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required String barcode,
  required String name,
  Value<String?> brand,
  required int calories,
  required double protein,
  required double carbs,
  required double fat,
  Value<double?> sugar,
  Value<double?> fiber,
  Value<double?> salt,
  Value<double?> caffeine,
  Value<bool> isLiquid,
  Value<String> source,
  Value<String?> category,
});
typedef $$ProductsTableUpdateCompanionBuilder = ProductsCompanion Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> barcode,
  Value<String> name,
  Value<String?> brand,
  Value<int> calories,
  Value<double> protein,
  Value<double> carbs,
  Value<double> fat,
  Value<double?> sugar,
  Value<double?> fiber,
  Value<double?> salt,
  Value<double?> caffeine,
  Value<bool> isLiquid,
  Value<String> source,
  Value<String?> category,
});

final class $$ProductsTableReferences
    extends BaseReferences<_$AppDatabase, $ProductsTable, Product> {
  $$ProductsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$NutritionLogsTable, List<NutritionLog>>
      _nutritionLogsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.nutritionLogs,
              aliasName: $_aliasNameGenerator(
                  db.products.id, db.nutritionLogs.productId));

  $$NutritionLogsTableProcessedTableManager get nutritionLogsRefs {
    final manager = $$NutritionLogsTableTableManager($_db, $_db.nutritionLogs)
        .filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_nutritionLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$MealItemsTable, List<MealItem>>
      _mealItemsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.mealItems,
              aliasName:
                  $_aliasNameGenerator(db.products.id, db.mealItems.productId));

  $$MealItemsTableProcessedTableManager get mealItemsRefs {
    final manager = $$MealItemsTableTableManager($_db, $_db.mealItems)
        .filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_mealItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get brand => $composableBuilder(
      column: $table.brand, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get calories => $composableBuilder(
      column: $table.calories, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get protein => $composableBuilder(
      column: $table.protein, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get carbs => $composableBuilder(
      column: $table.carbs, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fat => $composableBuilder(
      column: $table.fat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get sugar => $composableBuilder(
      column: $table.sugar, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fiber => $composableBuilder(
      column: $table.fiber, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get salt => $composableBuilder(
      column: $table.salt, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get caffeine => $composableBuilder(
      column: $table.caffeine, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isLiquid => $composableBuilder(
      column: $table.isLiquid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  Expression<bool> nutritionLogsRefs(
      Expression<bool> Function($$NutritionLogsTableFilterComposer f) f) {
    final $$NutritionLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.nutritionLogs,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NutritionLogsTableFilterComposer(
              $db: $db,
              $table: $db.nutritionLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> mealItemsRefs(
      Expression<bool> Function($$MealItemsTableFilterComposer f) f) {
    final $$MealItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.mealItems,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MealItemsTableFilterComposer(
              $db: $db,
              $table: $db.mealItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get brand => $composableBuilder(
      column: $table.brand, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get calories => $composableBuilder(
      column: $table.calories, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get protein => $composableBuilder(
      column: $table.protein, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get carbs => $composableBuilder(
      column: $table.carbs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fat => $composableBuilder(
      column: $table.fat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get sugar => $composableBuilder(
      column: $table.sugar, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fiber => $composableBuilder(
      column: $table.fiber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get salt => $composableBuilder(
      column: $table.salt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get caffeine => $composableBuilder(
      column: $table.caffeine, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isLiquid => $composableBuilder(
      column: $table.isLiquid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<int> get calories =>
      $composableBuilder(column: $table.calories, builder: (column) => column);

  GeneratedColumn<double> get protein =>
      $composableBuilder(column: $table.protein, builder: (column) => column);

  GeneratedColumn<double> get carbs =>
      $composableBuilder(column: $table.carbs, builder: (column) => column);

  GeneratedColumn<double> get fat =>
      $composableBuilder(column: $table.fat, builder: (column) => column);

  GeneratedColumn<double> get sugar =>
      $composableBuilder(column: $table.sugar, builder: (column) => column);

  GeneratedColumn<double> get fiber =>
      $composableBuilder(column: $table.fiber, builder: (column) => column);

  GeneratedColumn<double> get salt =>
      $composableBuilder(column: $table.salt, builder: (column) => column);

  GeneratedColumn<double> get caffeine =>
      $composableBuilder(column: $table.caffeine, builder: (column) => column);

  GeneratedColumn<bool> get isLiquid =>
      $composableBuilder(column: $table.isLiquid, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  Expression<T> nutritionLogsRefs<T extends Object>(
      Expression<T> Function($$NutritionLogsTableAnnotationComposer a) f) {
    final $$NutritionLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.nutritionLogs,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NutritionLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.nutritionLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> mealItemsRefs<T extends Object>(
      Expression<T> Function($$MealItemsTableAnnotationComposer a) f) {
    final $$MealItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.mealItems,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MealItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.mealItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProductsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProductsTable,
    Product,
    $$ProductsTableFilterComposer,
    $$ProductsTableOrderingComposer,
    $$ProductsTableAnnotationComposer,
    $$ProductsTableCreateCompanionBuilder,
    $$ProductsTableUpdateCompanionBuilder,
    (Product, $$ProductsTableReferences),
    Product,
    PrefetchHooks Function({bool nutritionLogsRefs, bool mealItemsRefs})> {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> barcode = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> brand = const Value.absent(),
            Value<int> calories = const Value.absent(),
            Value<double> protein = const Value.absent(),
            Value<double> carbs = const Value.absent(),
            Value<double> fat = const Value.absent(),
            Value<double?> sugar = const Value.absent(),
            Value<double?> fiber = const Value.absent(),
            Value<double?> salt = const Value.absent(),
            Value<double?> caffeine = const Value.absent(),
            Value<bool> isLiquid = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String?> category = const Value.absent(),
          }) =>
              ProductsCompanion(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            barcode: barcode,
            name: name,
            brand: brand,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            sugar: sugar,
            fiber: fiber,
            salt: salt,
            caffeine: caffeine,
            isLiquid: isLiquid,
            source: source,
            category: category,
          ),
          createCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            required String barcode,
            required String name,
            Value<String?> brand = const Value.absent(),
            required int calories,
            required double protein,
            required double carbs,
            required double fat,
            Value<double?> sugar = const Value.absent(),
            Value<double?> fiber = const Value.absent(),
            Value<double?> salt = const Value.absent(),
            Value<double?> caffeine = const Value.absent(),
            Value<bool> isLiquid = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String?> category = const Value.absent(),
          }) =>
              ProductsCompanion.insert(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            barcode: barcode,
            name: name,
            brand: brand,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            sugar: sugar,
            fiber: fiber,
            salt: salt,
            caffeine: caffeine,
            isLiquid: isLiquid,
            source: source,
            category: category,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ProductsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {nutritionLogsRefs = false, mealItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (nutritionLogsRefs) db.nutritionLogs,
                if (mealItemsRefs) db.mealItems
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (nutritionLogsRefs)
                    await $_getPrefetchedData<Product, $ProductsTable,
                            NutritionLog>(
                        currentTable: table,
                        referencedTable: $$ProductsTableReferences
                            ._nutritionLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProductsTableReferences(db, table, p0)
                                .nutritionLogsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.productId == item.id),
                        typedResults: items),
                  if (mealItemsRefs)
                    await $_getPrefetchedData<Product, $ProductsTable,
                            MealItem>(
                        currentTable: table,
                        referencedTable:
                            $$ProductsTableReferences._mealItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProductsTableReferences(db, table, p0)
                                .mealItemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.productId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ProductsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProductsTable,
    Product,
    $$ProductsTableFilterComposer,
    $$ProductsTableOrderingComposer,
    $$ProductsTableAnnotationComposer,
    $$ProductsTableCreateCompanionBuilder,
    $$ProductsTableUpdateCompanionBuilder,
    (Product, $$ProductsTableReferences),
    Product,
    PrefetchHooks Function({bool nutritionLogsRefs, bool mealItemsRefs})>;
typedef $$NutritionLogsTableCreateCompanionBuilder = NutritionLogsCompanion
    Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> userId,
  Value<String?> productId,
  Value<String?> legacyBarcode,
  required DateTime consumedAt,
  required double amount,
  Value<String> mealType,
});
typedef $$NutritionLogsTableUpdateCompanionBuilder = NutritionLogsCompanion
    Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> userId,
  Value<String?> productId,
  Value<String?> legacyBarcode,
  Value<DateTime> consumedAt,
  Value<double> amount,
  Value<String> mealType,
});

final class $$NutritionLogsTableReferences
    extends BaseReferences<_$AppDatabase, $NutritionLogsTable, NutritionLog> {
  $$NutritionLogsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias(
          $_aliasNameGenerator(db.nutritionLogs.productId, db.products.id));

  $$ProductsTableProcessedTableManager? get productId {
    final $_column = $_itemColumn<String>('product_id');
    if ($_column == null) return null;
    final manager = $$ProductsTableTableManager($_db, $_db.products)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$SupplementLogsTable, List<SupplementLog>>
      _supplementLogsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.supplementLogs,
              aliasName: $_aliasNameGenerator(
                  db.nutritionLogs.id, db.supplementLogs.sourceNutritionLogId));

  $$SupplementLogsTableProcessedTableManager get supplementLogsRefs {
    final manager = $$SupplementLogsTableTableManager($_db, $_db.supplementLogs)
        .filter((f) =>
            f.sourceNutritionLogId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_supplementLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$FluidLogsTable, List<FluidLog>>
      _fluidLogsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.fluidLogs,
              aliasName: $_aliasNameGenerator(
                  db.nutritionLogs.id, db.fluidLogs.linkedNutritionLogId));

  $$FluidLogsTableProcessedTableManager get fluidLogsRefs {
    final manager = $$FluidLogsTableTableManager($_db, $_db.fluidLogs).filter(
        (f) =>
            f.linkedNutritionLogId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_fluidLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$NutritionLogsTableFilterComposer
    extends Composer<_$AppDatabase, $NutritionLogsTable> {
  $$NutritionLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get legacyBarcode => $composableBuilder(
      column: $table.legacyBarcode, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get consumedAt => $composableBuilder(
      column: $table.consumedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mealType => $composableBuilder(
      column: $table.mealType, builder: (column) => ColumnFilters(column));

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableFilterComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> supplementLogsRefs(
      Expression<bool> Function($$SupplementLogsTableFilterComposer f) f) {
    final $$SupplementLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.supplementLogs,
        getReferencedColumn: (t) => t.sourceNutritionLogId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SupplementLogsTableFilterComposer(
              $db: $db,
              $table: $db.supplementLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> fluidLogsRefs(
      Expression<bool> Function($$FluidLogsTableFilterComposer f) f) {
    final $$FluidLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.fluidLogs,
        getReferencedColumn: (t) => t.linkedNutritionLogId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FluidLogsTableFilterComposer(
              $db: $db,
              $table: $db.fluidLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$NutritionLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $NutritionLogsTable> {
  $$NutritionLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get legacyBarcode => $composableBuilder(
      column: $table.legacyBarcode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get consumedAt => $composableBuilder(
      column: $table.consumedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mealType => $composableBuilder(
      column: $table.mealType, builder: (column) => ColumnOrderings(column));

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableOrderingComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$NutritionLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NutritionLogsTable> {
  $$NutritionLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get legacyBarcode => $composableBuilder(
      column: $table.legacyBarcode, builder: (column) => column);

  GeneratedColumn<DateTime> get consumedAt => $composableBuilder(
      column: $table.consumedAt, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get mealType =>
      $composableBuilder(column: $table.mealType, builder: (column) => column);

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableAnnotationComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> supplementLogsRefs<T extends Object>(
      Expression<T> Function($$SupplementLogsTableAnnotationComposer a) f) {
    final $$SupplementLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.supplementLogs,
        getReferencedColumn: (t) => t.sourceNutritionLogId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SupplementLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.supplementLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> fluidLogsRefs<T extends Object>(
      Expression<T> Function($$FluidLogsTableAnnotationComposer a) f) {
    final $$FluidLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.fluidLogs,
        getReferencedColumn: (t) => t.linkedNutritionLogId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FluidLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.fluidLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$NutritionLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NutritionLogsTable,
    NutritionLog,
    $$NutritionLogsTableFilterComposer,
    $$NutritionLogsTableOrderingComposer,
    $$NutritionLogsTableAnnotationComposer,
    $$NutritionLogsTableCreateCompanionBuilder,
    $$NutritionLogsTableUpdateCompanionBuilder,
    (NutritionLog, $$NutritionLogsTableReferences),
    NutritionLog,
    PrefetchHooks Function(
        {bool productId, bool supplementLogsRefs, bool fluidLogsRefs})> {
  $$NutritionLogsTableTableManager(_$AppDatabase db, $NutritionLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NutritionLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NutritionLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NutritionLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> productId = const Value.absent(),
            Value<String?> legacyBarcode = const Value.absent(),
            Value<DateTime> consumedAt = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> mealType = const Value.absent(),
          }) =>
              NutritionLogsCompanion(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            userId: userId,
            productId: productId,
            legacyBarcode: legacyBarcode,
            consumedAt: consumedAt,
            amount: amount,
            mealType: mealType,
          ),
          createCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> productId = const Value.absent(),
            Value<String?> legacyBarcode = const Value.absent(),
            required DateTime consumedAt,
            required double amount,
            Value<String> mealType = const Value.absent(),
          }) =>
              NutritionLogsCompanion.insert(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            userId: userId,
            productId: productId,
            legacyBarcode: legacyBarcode,
            consumedAt: consumedAt,
            amount: amount,
            mealType: mealType,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$NutritionLogsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {productId = false,
              supplementLogsRefs = false,
              fluidLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (supplementLogsRefs) db.supplementLogs,
                if (fluidLogsRefs) db.fluidLogs
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (productId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.productId,
                    referencedTable:
                        $$NutritionLogsTableReferences._productIdTable(db),
                    referencedColumn:
                        $$NutritionLogsTableReferences._productIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (supplementLogsRefs)
                    await $_getPrefetchedData<NutritionLog, $NutritionLogsTable,
                            SupplementLog>(
                        currentTable: table,
                        referencedTable: $$NutritionLogsTableReferences
                            ._supplementLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$NutritionLogsTableReferences(db, table, p0)
                                .supplementLogsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceNutritionLogId == item.id),
                        typedResults: items),
                  if (fluidLogsRefs)
                    await $_getPrefetchedData<NutritionLog, $NutritionLogsTable,
                            FluidLog>(
                        currentTable: table,
                        referencedTable: $$NutritionLogsTableReferences
                            ._fluidLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$NutritionLogsTableReferences(db, table, p0)
                                .fluidLogsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems.where(
                                (e) => e.linkedNutritionLogId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$NutritionLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NutritionLogsTable,
    NutritionLog,
    $$NutritionLogsTableFilterComposer,
    $$NutritionLogsTableOrderingComposer,
    $$NutritionLogsTableAnnotationComposer,
    $$NutritionLogsTableCreateCompanionBuilder,
    $$NutritionLogsTableUpdateCompanionBuilder,
    (NutritionLog, $$NutritionLogsTableReferences),
    NutritionLog,
    PrefetchHooks Function(
        {bool productId, bool supplementLogsRefs, bool fluidLogsRefs})>;
typedef $$SupplementsTableCreateCompanionBuilder = SupplementsCompanion
    Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> code,
  required String name,
  required double dose,
  required String unit,
  Value<double?> dailyGoal,
  Value<double?> dailyLimit,
  Value<String?> notes,
  Value<bool> isBuiltin,
  Value<bool> isTracked,
});
typedef $$SupplementsTableUpdateCompanionBuilder = SupplementsCompanion
    Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> code,
  Value<String> name,
  Value<double> dose,
  Value<String> unit,
  Value<double?> dailyGoal,
  Value<double?> dailyLimit,
  Value<String?> notes,
  Value<bool> isBuiltin,
  Value<bool> isTracked,
});

final class $$SupplementsTableReferences
    extends BaseReferences<_$AppDatabase, $SupplementsTable, Supplement> {
  $$SupplementsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SupplementLogsTable, List<SupplementLog>>
      _supplementLogsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.supplementLogs,
              aliasName: $_aliasNameGenerator(
                  db.supplements.id, db.supplementLogs.supplementId));

  $$SupplementLogsTableProcessedTableManager get supplementLogsRefs {
    final manager = $$SupplementLogsTableTableManager($_db, $_db.supplementLogs)
        .filter(
            (f) => f.supplementId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_supplementLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$SupplementSettingsHistoryTable,
      List<SupplementSettingsHistoryData>> _supplementSettingsHistoryRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.supplementSettingsHistory,
          aliasName: $_aliasNameGenerator(
              db.supplements.id, db.supplementSettingsHistory.supplementId));

  $$SupplementSettingsHistoryTableProcessedTableManager
      get supplementSettingsHistoryRefs {
    final manager = $$SupplementSettingsHistoryTableTableManager(
            $_db, $_db.supplementSettingsHistory)
        .filter(
            (f) => f.supplementId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult
        .readTableOrNull(_supplementSettingsHistoryRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$SupplementsTableFilterComposer
    extends Composer<_$AppDatabase, $SupplementsTable> {
  $$SupplementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get dose => $composableBuilder(
      column: $table.dose, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get dailyGoal => $composableBuilder(
      column: $table.dailyGoal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get dailyLimit => $composableBuilder(
      column: $table.dailyLimit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isBuiltin => $composableBuilder(
      column: $table.isBuiltin, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isTracked => $composableBuilder(
      column: $table.isTracked, builder: (column) => ColumnFilters(column));

  Expression<bool> supplementLogsRefs(
      Expression<bool> Function($$SupplementLogsTableFilterComposer f) f) {
    final $$SupplementLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.supplementLogs,
        getReferencedColumn: (t) => t.supplementId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SupplementLogsTableFilterComposer(
              $db: $db,
              $table: $db.supplementLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> supplementSettingsHistoryRefs(
      Expression<bool> Function(
              $$SupplementSettingsHistoryTableFilterComposer f)
          f) {
    final $$SupplementSettingsHistoryTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.supplementSettingsHistory,
            getReferencedColumn: (t) => t.supplementId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$SupplementSettingsHistoryTableFilterComposer(
                  $db: $db,
                  $table: $db.supplementSettingsHistory,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$SupplementsTableOrderingComposer
    extends Composer<_$AppDatabase, $SupplementsTable> {
  $$SupplementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get dose => $composableBuilder(
      column: $table.dose, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get dailyGoal => $composableBuilder(
      column: $table.dailyGoal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get dailyLimit => $composableBuilder(
      column: $table.dailyLimit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isBuiltin => $composableBuilder(
      column: $table.isBuiltin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isTracked => $composableBuilder(
      column: $table.isTracked, builder: (column) => ColumnOrderings(column));
}

class $$SupplementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SupplementsTable> {
  $$SupplementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get dose =>
      $composableBuilder(column: $table.dose, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get dailyGoal =>
      $composableBuilder(column: $table.dailyGoal, builder: (column) => column);

  GeneratedColumn<double> get dailyLimit => $composableBuilder(
      column: $table.dailyLimit, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isBuiltin =>
      $composableBuilder(column: $table.isBuiltin, builder: (column) => column);

  GeneratedColumn<bool> get isTracked =>
      $composableBuilder(column: $table.isTracked, builder: (column) => column);

  Expression<T> supplementLogsRefs<T extends Object>(
      Expression<T> Function($$SupplementLogsTableAnnotationComposer a) f) {
    final $$SupplementLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.supplementLogs,
        getReferencedColumn: (t) => t.supplementId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SupplementLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.supplementLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> supplementSettingsHistoryRefs<T extends Object>(
      Expression<T> Function(
              $$SupplementSettingsHistoryTableAnnotationComposer a)
          f) {
    final $$SupplementSettingsHistoryTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.supplementSettingsHistory,
            getReferencedColumn: (t) => t.supplementId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$SupplementSettingsHistoryTableAnnotationComposer(
                  $db: $db,
                  $table: $db.supplementSettingsHistory,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$SupplementsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SupplementsTable,
    Supplement,
    $$SupplementsTableFilterComposer,
    $$SupplementsTableOrderingComposer,
    $$SupplementsTableAnnotationComposer,
    $$SupplementsTableCreateCompanionBuilder,
    $$SupplementsTableUpdateCompanionBuilder,
    (Supplement, $$SupplementsTableReferences),
    Supplement,
    PrefetchHooks Function(
        {bool supplementLogsRefs, bool supplementSettingsHistoryRefs})> {
  $$SupplementsTableTableManager(_$AppDatabase db, $SupplementsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SupplementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SupplementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SupplementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String?> code = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> dose = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<double?> dailyGoal = const Value.absent(),
            Value<double?> dailyLimit = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool> isBuiltin = const Value.absent(),
            Value<bool> isTracked = const Value.absent(),
          }) =>
              SupplementsCompanion(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            code: code,
            name: name,
            dose: dose,
            unit: unit,
            dailyGoal: dailyGoal,
            dailyLimit: dailyLimit,
            notes: notes,
            isBuiltin: isBuiltin,
            isTracked: isTracked,
          ),
          createCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String?> code = const Value.absent(),
            required String name,
            required double dose,
            required String unit,
            Value<double?> dailyGoal = const Value.absent(),
            Value<double?> dailyLimit = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool> isBuiltin = const Value.absent(),
            Value<bool> isTracked = const Value.absent(),
          }) =>
              SupplementsCompanion.insert(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            code: code,
            name: name,
            dose: dose,
            unit: unit,
            dailyGoal: dailyGoal,
            dailyLimit: dailyLimit,
            notes: notes,
            isBuiltin: isBuiltin,
            isTracked: isTracked,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SupplementsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {supplementLogsRefs = false,
              supplementSettingsHistoryRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (supplementLogsRefs) db.supplementLogs,
                if (supplementSettingsHistoryRefs) db.supplementSettingsHistory
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (supplementLogsRefs)
                    await $_getPrefetchedData<Supplement, $SupplementsTable,
                            SupplementLog>(
                        currentTable: table,
                        referencedTable: $$SupplementsTableReferences
                            ._supplementLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SupplementsTableReferences(db, table, p0)
                                .supplementLogsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.supplementId == item.id),
                        typedResults: items),
                  if (supplementSettingsHistoryRefs)
                    await $_getPrefetchedData<Supplement, $SupplementsTable,
                            SupplementSettingsHistoryData>(
                        currentTable: table,
                        referencedTable: $$SupplementsTableReferences
                            ._supplementSettingsHistoryRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SupplementsTableReferences(db, table, p0)
                                .supplementSettingsHistoryRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.supplementId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$SupplementsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SupplementsTable,
    Supplement,
    $$SupplementsTableFilterComposer,
    $$SupplementsTableOrderingComposer,
    $$SupplementsTableAnnotationComposer,
    $$SupplementsTableCreateCompanionBuilder,
    $$SupplementsTableUpdateCompanionBuilder,
    (Supplement, $$SupplementsTableReferences),
    Supplement,
    PrefetchHooks Function(
        {bool supplementLogsRefs, bool supplementSettingsHistoryRefs})>;
typedef $$SupplementLogsTableCreateCompanionBuilder = SupplementLogsCompanion
    Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required String supplementId,
  required DateTime takenAt,
  required double amount,
  Value<String?> sourceNutritionLogId,
});
typedef $$SupplementLogsTableUpdateCompanionBuilder = SupplementLogsCompanion
    Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> supplementId,
  Value<DateTime> takenAt,
  Value<double> amount,
  Value<String?> sourceNutritionLogId,
});

final class $$SupplementLogsTableReferences
    extends BaseReferences<_$AppDatabase, $SupplementLogsTable, SupplementLog> {
  $$SupplementLogsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $SupplementsTable _supplementIdTable(_$AppDatabase db) =>
      db.supplements.createAlias($_aliasNameGenerator(
          db.supplementLogs.supplementId, db.supplements.id));

  $$SupplementsTableProcessedTableManager get supplementId {
    final $_column = $_itemColumn<String>('supplement_id')!;

    final manager = $$SupplementsTableTableManager($_db, $_db.supplements)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_supplementIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $NutritionLogsTable _sourceNutritionLogIdTable(_$AppDatabase db) =>
      db.nutritionLogs.createAlias($_aliasNameGenerator(
          db.supplementLogs.sourceNutritionLogId, db.nutritionLogs.id));

  $$NutritionLogsTableProcessedTableManager? get sourceNutritionLogId {
    final $_column = $_itemColumn<String>('source_nutrition_log_id');
    if ($_column == null) return null;
    final manager = $$NutritionLogsTableTableManager($_db, $_db.nutritionLogs)
        .filter((f) => f.id.sqlEquals($_column));
    final item =
        $_typedResult.readTableOrNull(_sourceNutritionLogIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$SupplementLogsTableFilterComposer
    extends Composer<_$AppDatabase, $SupplementLogsTable> {
  $$SupplementLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get takenAt => $composableBuilder(
      column: $table.takenAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  $$SupplementsTableFilterComposer get supplementId {
    final $$SupplementsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.supplementId,
        referencedTable: $db.supplements,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SupplementsTableFilterComposer(
              $db: $db,
              $table: $db.supplements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$NutritionLogsTableFilterComposer get sourceNutritionLogId {
    final $$NutritionLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourceNutritionLogId,
        referencedTable: $db.nutritionLogs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NutritionLogsTableFilterComposer(
              $db: $db,
              $table: $db.nutritionLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SupplementLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $SupplementLogsTable> {
  $$SupplementLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get takenAt => $composableBuilder(
      column: $table.takenAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  $$SupplementsTableOrderingComposer get supplementId {
    final $$SupplementsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.supplementId,
        referencedTable: $db.supplements,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SupplementsTableOrderingComposer(
              $db: $db,
              $table: $db.supplements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$NutritionLogsTableOrderingComposer get sourceNutritionLogId {
    final $$NutritionLogsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourceNutritionLogId,
        referencedTable: $db.nutritionLogs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NutritionLogsTableOrderingComposer(
              $db: $db,
              $table: $db.nutritionLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SupplementLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SupplementLogsTable> {
  $$SupplementLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get takenAt =>
      $composableBuilder(column: $table.takenAt, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  $$SupplementsTableAnnotationComposer get supplementId {
    final $$SupplementsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.supplementId,
        referencedTable: $db.supplements,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SupplementsTableAnnotationComposer(
              $db: $db,
              $table: $db.supplements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$NutritionLogsTableAnnotationComposer get sourceNutritionLogId {
    final $$NutritionLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourceNutritionLogId,
        referencedTable: $db.nutritionLogs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NutritionLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.nutritionLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SupplementLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SupplementLogsTable,
    SupplementLog,
    $$SupplementLogsTableFilterComposer,
    $$SupplementLogsTableOrderingComposer,
    $$SupplementLogsTableAnnotationComposer,
    $$SupplementLogsTableCreateCompanionBuilder,
    $$SupplementLogsTableUpdateCompanionBuilder,
    (SupplementLog, $$SupplementLogsTableReferences),
    SupplementLog,
    PrefetchHooks Function({bool supplementId, bool sourceNutritionLogId})> {
  $$SupplementLogsTableTableManager(
      _$AppDatabase db, $SupplementLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SupplementLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SupplementLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SupplementLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> supplementId = const Value.absent(),
            Value<DateTime> takenAt = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String?> sourceNutritionLogId = const Value.absent(),
          }) =>
              SupplementLogsCompanion(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            supplementId: supplementId,
            takenAt: takenAt,
            amount: amount,
            sourceNutritionLogId: sourceNutritionLogId,
          ),
          createCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            required String supplementId,
            required DateTime takenAt,
            required double amount,
            Value<String?> sourceNutritionLogId = const Value.absent(),
          }) =>
              SupplementLogsCompanion.insert(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            supplementId: supplementId,
            takenAt: takenAt,
            amount: amount,
            sourceNutritionLogId: sourceNutritionLogId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SupplementLogsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {supplementId = false, sourceNutritionLogId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (supplementId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.supplementId,
                    referencedTable:
                        $$SupplementLogsTableReferences._supplementIdTable(db),
                    referencedColumn: $$SupplementLogsTableReferences
                        ._supplementIdTable(db)
                        .id,
                  ) as T;
                }
                if (sourceNutritionLogId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sourceNutritionLogId,
                    referencedTable: $$SupplementLogsTableReferences
                        ._sourceNutritionLogIdTable(db),
                    referencedColumn: $$SupplementLogsTableReferences
                        ._sourceNutritionLogIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$SupplementLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SupplementLogsTable,
    SupplementLog,
    $$SupplementLogsTableFilterComposer,
    $$SupplementLogsTableOrderingComposer,
    $$SupplementLogsTableAnnotationComposer,
    $$SupplementLogsTableCreateCompanionBuilder,
    $$SupplementLogsTableUpdateCompanionBuilder,
    (SupplementLog, $$SupplementLogsTableReferences),
    SupplementLog,
    PrefetchHooks Function({bool supplementId, bool sourceNutritionLogId})>;
typedef $$FluidLogsTableCreateCompanionBuilder = FluidLogsCompanion Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required DateTime consumedAt,
  required int amountMl,
  required String name,
  Value<int?> kcal,
  Value<double?> sugarPer100ml,
  Value<double?> caffeinePer100ml,
  Value<String?> linkedNutritionLogId,
});
typedef $$FluidLogsTableUpdateCompanionBuilder = FluidLogsCompanion Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<DateTime> consumedAt,
  Value<int> amountMl,
  Value<String> name,
  Value<int?> kcal,
  Value<double?> sugarPer100ml,
  Value<double?> caffeinePer100ml,
  Value<String?> linkedNutritionLogId,
});

final class $$FluidLogsTableReferences
    extends BaseReferences<_$AppDatabase, $FluidLogsTable, FluidLog> {
  $$FluidLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $NutritionLogsTable _linkedNutritionLogIdTable(_$AppDatabase db) =>
      db.nutritionLogs.createAlias($_aliasNameGenerator(
          db.fluidLogs.linkedNutritionLogId, db.nutritionLogs.id));

  $$NutritionLogsTableProcessedTableManager? get linkedNutritionLogId {
    final $_column = $_itemColumn<String>('linked_nutrition_log_id');
    if ($_column == null) return null;
    final manager = $$NutritionLogsTableTableManager($_db, $_db.nutritionLogs)
        .filter((f) => f.id.sqlEquals($_column));
    final item =
        $_typedResult.readTableOrNull(_linkedNutritionLogIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$FluidLogsTableFilterComposer
    extends Composer<_$AppDatabase, $FluidLogsTable> {
  $$FluidLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get consumedAt => $composableBuilder(
      column: $table.consumedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountMl => $composableBuilder(
      column: $table.amountMl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get kcal => $composableBuilder(
      column: $table.kcal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get sugarPer100ml => $composableBuilder(
      column: $table.sugarPer100ml, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get caffeinePer100ml => $composableBuilder(
      column: $table.caffeinePer100ml,
      builder: (column) => ColumnFilters(column));

  $$NutritionLogsTableFilterComposer get linkedNutritionLogId {
    final $$NutritionLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.linkedNutritionLogId,
        referencedTable: $db.nutritionLogs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NutritionLogsTableFilterComposer(
              $db: $db,
              $table: $db.nutritionLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FluidLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $FluidLogsTable> {
  $$FluidLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get consumedAt => $composableBuilder(
      column: $table.consumedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountMl => $composableBuilder(
      column: $table.amountMl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get kcal => $composableBuilder(
      column: $table.kcal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get sugarPer100ml => $composableBuilder(
      column: $table.sugarPer100ml,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get caffeinePer100ml => $composableBuilder(
      column: $table.caffeinePer100ml,
      builder: (column) => ColumnOrderings(column));

  $$NutritionLogsTableOrderingComposer get linkedNutritionLogId {
    final $$NutritionLogsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.linkedNutritionLogId,
        referencedTable: $db.nutritionLogs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NutritionLogsTableOrderingComposer(
              $db: $db,
              $table: $db.nutritionLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FluidLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FluidLogsTable> {
  $$FluidLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get consumedAt => $composableBuilder(
      column: $table.consumedAt, builder: (column) => column);

  GeneratedColumn<int> get amountMl =>
      $composableBuilder(column: $table.amountMl, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get kcal =>
      $composableBuilder(column: $table.kcal, builder: (column) => column);

  GeneratedColumn<double> get sugarPer100ml => $composableBuilder(
      column: $table.sugarPer100ml, builder: (column) => column);

  GeneratedColumn<double> get caffeinePer100ml => $composableBuilder(
      column: $table.caffeinePer100ml, builder: (column) => column);

  $$NutritionLogsTableAnnotationComposer get linkedNutritionLogId {
    final $$NutritionLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.linkedNutritionLogId,
        referencedTable: $db.nutritionLogs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NutritionLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.nutritionLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FluidLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FluidLogsTable,
    FluidLog,
    $$FluidLogsTableFilterComposer,
    $$FluidLogsTableOrderingComposer,
    $$FluidLogsTableAnnotationComposer,
    $$FluidLogsTableCreateCompanionBuilder,
    $$FluidLogsTableUpdateCompanionBuilder,
    (FluidLog, $$FluidLogsTableReferences),
    FluidLog,
    PrefetchHooks Function({bool linkedNutritionLogId})> {
  $$FluidLogsTableTableManager(_$AppDatabase db, $FluidLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FluidLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FluidLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FluidLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<DateTime> consumedAt = const Value.absent(),
            Value<int> amountMl = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int?> kcal = const Value.absent(),
            Value<double?> sugarPer100ml = const Value.absent(),
            Value<double?> caffeinePer100ml = const Value.absent(),
            Value<String?> linkedNutritionLogId = const Value.absent(),
          }) =>
              FluidLogsCompanion(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            consumedAt: consumedAt,
            amountMl: amountMl,
            name: name,
            kcal: kcal,
            sugarPer100ml: sugarPer100ml,
            caffeinePer100ml: caffeinePer100ml,
            linkedNutritionLogId: linkedNutritionLogId,
          ),
          createCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            required DateTime consumedAt,
            required int amountMl,
            required String name,
            Value<int?> kcal = const Value.absent(),
            Value<double?> sugarPer100ml = const Value.absent(),
            Value<double?> caffeinePer100ml = const Value.absent(),
            Value<String?> linkedNutritionLogId = const Value.absent(),
          }) =>
              FluidLogsCompanion.insert(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            consumedAt: consumedAt,
            amountMl: amountMl,
            name: name,
            kcal: kcal,
            sugarPer100ml: sugarPer100ml,
            caffeinePer100ml: caffeinePer100ml,
            linkedNutritionLogId: linkedNutritionLogId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$FluidLogsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({linkedNutritionLogId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (linkedNutritionLogId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.linkedNutritionLogId,
                    referencedTable: $$FluidLogsTableReferences
                        ._linkedNutritionLogIdTable(db),
                    referencedColumn: $$FluidLogsTableReferences
                        ._linkedNutritionLogIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$FluidLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FluidLogsTable,
    FluidLog,
    $$FluidLogsTableFilterComposer,
    $$FluidLogsTableOrderingComposer,
    $$FluidLogsTableAnnotationComposer,
    $$FluidLogsTableCreateCompanionBuilder,
    $$FluidLogsTableUpdateCompanionBuilder,
    (FluidLog, $$FluidLogsTableReferences),
    FluidLog,
    PrefetchHooks Function({bool linkedNutritionLogId})>;
typedef $$MeasurementsTableCreateCompanionBuilder = MeasurementsCompanion
    Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> userId,
  required String type,
  required double value,
  required String unit,
  required DateTime date,
  Value<int?> legacySessionId,
});
typedef $$MeasurementsTableUpdateCompanionBuilder = MeasurementsCompanion
    Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> userId,
  Value<String> type,
  Value<double> value,
  Value<String> unit,
  Value<DateTime> date,
  Value<int?> legacySessionId,
});

class $$MeasurementsTableFilterComposer
    extends Composer<_$AppDatabase, $MeasurementsTable> {
  $$MeasurementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get legacySessionId => $composableBuilder(
      column: $table.legacySessionId,
      builder: (column) => ColumnFilters(column));
}

class $$MeasurementsTableOrderingComposer
    extends Composer<_$AppDatabase, $MeasurementsTable> {
  $$MeasurementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get legacySessionId => $composableBuilder(
      column: $table.legacySessionId,
      builder: (column) => ColumnOrderings(column));
}

class $$MeasurementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MeasurementsTable> {
  $$MeasurementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get legacySessionId => $composableBuilder(
      column: $table.legacySessionId, builder: (column) => column);
}

class $$MeasurementsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MeasurementsTable,
    Measurement,
    $$MeasurementsTableFilterComposer,
    $$MeasurementsTableOrderingComposer,
    $$MeasurementsTableAnnotationComposer,
    $$MeasurementsTableCreateCompanionBuilder,
    $$MeasurementsTableUpdateCompanionBuilder,
    (
      Measurement,
      BaseReferences<_$AppDatabase, $MeasurementsTable, Measurement>
    ),
    Measurement,
    PrefetchHooks Function()> {
  $$MeasurementsTableTableManager(_$AppDatabase db, $MeasurementsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MeasurementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MeasurementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MeasurementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<double> value = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<int?> legacySessionId = const Value.absent(),
          }) =>
              MeasurementsCompanion(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            userId: userId,
            type: type,
            value: value,
            unit: unit,
            date: date,
            legacySessionId: legacySessionId,
          ),
          createCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            required String type,
            required double value,
            required String unit,
            required DateTime date,
            Value<int?> legacySessionId = const Value.absent(),
          }) =>
              MeasurementsCompanion.insert(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            userId: userId,
            type: type,
            value: value,
            unit: unit,
            date: date,
            legacySessionId: legacySessionId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MeasurementsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MeasurementsTable,
    Measurement,
    $$MeasurementsTableFilterComposer,
    $$MeasurementsTableOrderingComposer,
    $$MeasurementsTableAnnotationComposer,
    $$MeasurementsTableCreateCompanionBuilder,
    $$MeasurementsTableUpdateCompanionBuilder,
    (
      Measurement,
      BaseReferences<_$AppDatabase, $MeasurementsTable, Measurement>
    ),
    Measurement,
    PrefetchHooks Function()>;
typedef $$PostsTableCreateCompanionBuilder = PostsCompanion Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required String userId,
  required String type,
  Value<String?> referenceId,
  Value<String?> metadata,
  Value<String?> content,
});
typedef $$PostsTableUpdateCompanionBuilder = PostsCompanion Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> userId,
  Value<String> type,
  Value<String?> referenceId,
  Value<String?> metadata,
  Value<String?> content,
});

final class $$PostsTableReferences
    extends BaseReferences<_$AppDatabase, $PostsTable, Post> {
  $$PostsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SocialInteractionsTable, List<SocialInteraction>>
      _socialInteractionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.socialInteractions,
              aliasName: $_aliasNameGenerator(
                  db.posts.id, db.socialInteractions.postId));

  $$SocialInteractionsTableProcessedTableManager get socialInteractionsRefs {
    final manager =
        $$SocialInteractionsTableTableManager($_db, $_db.socialInteractions)
            .filter((f) => f.postId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_socialInteractionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PostsTableFilterComposer extends Composer<_$AppDatabase, $PostsTable> {
  $$PostsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get referenceId => $composableBuilder(
      column: $table.referenceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  Expression<bool> socialInteractionsRefs(
      Expression<bool> Function($$SocialInteractionsTableFilterComposer f) f) {
    final $$SocialInteractionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.socialInteractions,
        getReferencedColumn: (t) => t.postId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SocialInteractionsTableFilterComposer(
              $db: $db,
              $table: $db.socialInteractions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PostsTableOrderingComposer
    extends Composer<_$AppDatabase, $PostsTable> {
  $$PostsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get referenceId => $composableBuilder(
      column: $table.referenceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));
}

class $$PostsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PostsTable> {
  $$PostsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get referenceId => $composableBuilder(
      column: $table.referenceId, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  Expression<T> socialInteractionsRefs<T extends Object>(
      Expression<T> Function($$SocialInteractionsTableAnnotationComposer a) f) {
    final $$SocialInteractionsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.socialInteractions,
            getReferencedColumn: (t) => t.postId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$SocialInteractionsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.socialInteractions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$PostsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PostsTable,
    Post,
    $$PostsTableFilterComposer,
    $$PostsTableOrderingComposer,
    $$PostsTableAnnotationComposer,
    $$PostsTableCreateCompanionBuilder,
    $$PostsTableUpdateCompanionBuilder,
    (Post, $$PostsTableReferences),
    Post,
    PrefetchHooks Function({bool socialInteractionsRefs})> {
  $$PostsTableTableManager(_$AppDatabase db, $PostsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PostsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PostsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PostsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> referenceId = const Value.absent(),
            Value<String?> metadata = const Value.absent(),
            Value<String?> content = const Value.absent(),
          }) =>
              PostsCompanion(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            userId: userId,
            type: type,
            referenceId: referenceId,
            metadata: metadata,
            content: content,
          ),
          createCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            required String userId,
            required String type,
            Value<String?> referenceId = const Value.absent(),
            Value<String?> metadata = const Value.absent(),
            Value<String?> content = const Value.absent(),
          }) =>
              PostsCompanion.insert(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            userId: userId,
            type: type,
            referenceId: referenceId,
            metadata: metadata,
            content: content,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$PostsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({socialInteractionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (socialInteractionsRefs) db.socialInteractions
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (socialInteractionsRefs)
                    await $_getPrefetchedData<Post, $PostsTable,
                            SocialInteraction>(
                        currentTable: table,
                        referencedTable: $$PostsTableReferences
                            ._socialInteractionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PostsTableReferences(db, table, p0)
                                .socialInteractionsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.postId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$PostsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PostsTable,
    Post,
    $$PostsTableFilterComposer,
    $$PostsTableOrderingComposer,
    $$PostsTableAnnotationComposer,
    $$PostsTableCreateCompanionBuilder,
    $$PostsTableUpdateCompanionBuilder,
    (Post, $$PostsTableReferences),
    Post,
    PrefetchHooks Function({bool socialInteractionsRefs})>;
typedef $$SocialInteractionsTableCreateCompanionBuilder
    = SocialInteractionsCompanion Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required String postId,
  required String userId,
  required String type,
  Value<String?> content,
});
typedef $$SocialInteractionsTableUpdateCompanionBuilder
    = SocialInteractionsCompanion Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> postId,
  Value<String> userId,
  Value<String> type,
  Value<String?> content,
});

final class $$SocialInteractionsTableReferences extends BaseReferences<
    _$AppDatabase, $SocialInteractionsTable, SocialInteraction> {
  $$SocialInteractionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $PostsTable _postIdTable(_$AppDatabase db) => db.posts.createAlias(
      $_aliasNameGenerator(db.socialInteractions.postId, db.posts.id));

  $$PostsTableProcessedTableManager get postId {
    final $_column = $_itemColumn<String>('post_id')!;

    final manager = $$PostsTableTableManager($_db, $_db.posts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_postIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$SocialInteractionsTableFilterComposer
    extends Composer<_$AppDatabase, $SocialInteractionsTable> {
  $$SocialInteractionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  $$PostsTableFilterComposer get postId {
    final $$PostsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.postId,
        referencedTable: $db.posts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PostsTableFilterComposer(
              $db: $db,
              $table: $db.posts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SocialInteractionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SocialInteractionsTable> {
  $$SocialInteractionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  $$PostsTableOrderingComposer get postId {
    final $$PostsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.postId,
        referencedTable: $db.posts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PostsTableOrderingComposer(
              $db: $db,
              $table: $db.posts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SocialInteractionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SocialInteractionsTable> {
  $$SocialInteractionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  $$PostsTableAnnotationComposer get postId {
    final $$PostsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.postId,
        referencedTable: $db.posts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PostsTableAnnotationComposer(
              $db: $db,
              $table: $db.posts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SocialInteractionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SocialInteractionsTable,
    SocialInteraction,
    $$SocialInteractionsTableFilterComposer,
    $$SocialInteractionsTableOrderingComposer,
    $$SocialInteractionsTableAnnotationComposer,
    $$SocialInteractionsTableCreateCompanionBuilder,
    $$SocialInteractionsTableUpdateCompanionBuilder,
    (SocialInteraction, $$SocialInteractionsTableReferences),
    SocialInteraction,
    PrefetchHooks Function({bool postId})> {
  $$SocialInteractionsTableTableManager(
      _$AppDatabase db, $SocialInteractionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SocialInteractionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SocialInteractionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SocialInteractionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> postId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> content = const Value.absent(),
          }) =>
              SocialInteractionsCompanion(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            postId: postId,
            userId: userId,
            type: type,
            content: content,
          ),
          createCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            required String postId,
            required String userId,
            required String type,
            Value<String?> content = const Value.absent(),
          }) =>
              SocialInteractionsCompanion.insert(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            postId: postId,
            userId: userId,
            type: type,
            content: content,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SocialInteractionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({postId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (postId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.postId,
                    referencedTable:
                        $$SocialInteractionsTableReferences._postIdTable(db),
                    referencedColumn:
                        $$SocialInteractionsTableReferences._postIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$SocialInteractionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SocialInteractionsTable,
    SocialInteraction,
    $$SocialInteractionsTableFilterComposer,
    $$SocialInteractionsTableOrderingComposer,
    $$SocialInteractionsTableAnnotationComposer,
    $$SocialInteractionsTableCreateCompanionBuilder,
    $$SocialInteractionsTableUpdateCompanionBuilder,
    (SocialInteraction, $$SocialInteractionsTableReferences),
    SocialInteraction,
    PrefetchHooks Function({bool postId})>;
typedef $$MealsTableCreateCompanionBuilder = MealsCompanion Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> userId,
  required String name,
  Value<String?> notes,
});
typedef $$MealsTableUpdateCompanionBuilder = MealsCompanion Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> userId,
  Value<String> name,
  Value<String?> notes,
});

final class $$MealsTableReferences
    extends BaseReferences<_$AppDatabase, $MealsTable, Meal> {
  $$MealsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MealItemsTable, List<MealItem>>
      _mealItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.mealItems,
          aliasName: $_aliasNameGenerator(db.meals.id, db.mealItems.mealId));

  $$MealItemsTableProcessedTableManager get mealItemsRefs {
    final manager = $$MealItemsTableTableManager($_db, $_db.mealItems)
        .filter((f) => f.mealId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_mealItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$MealsTableFilterComposer extends Composer<_$AppDatabase, $MealsTable> {
  $$MealsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  Expression<bool> mealItemsRefs(
      Expression<bool> Function($$MealItemsTableFilterComposer f) f) {
    final $$MealItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.mealItems,
        getReferencedColumn: (t) => t.mealId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MealItemsTableFilterComposer(
              $db: $db,
              $table: $db.mealItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$MealsTableOrderingComposer
    extends Composer<_$AppDatabase, $MealsTable> {
  $$MealsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));
}

class $$MealsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealsTable> {
  $$MealsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  Expression<T> mealItemsRefs<T extends Object>(
      Expression<T> Function($$MealItemsTableAnnotationComposer a) f) {
    final $$MealItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.mealItems,
        getReferencedColumn: (t) => t.mealId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MealItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.mealItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$MealsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MealsTable,
    Meal,
    $$MealsTableFilterComposer,
    $$MealsTableOrderingComposer,
    $$MealsTableAnnotationComposer,
    $$MealsTableCreateCompanionBuilder,
    $$MealsTableUpdateCompanionBuilder,
    (Meal, $$MealsTableReferences),
    Meal,
    PrefetchHooks Function({bool mealItemsRefs})> {
  $$MealsTableTableManager(_$AppDatabase db, $MealsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> notes = const Value.absent(),
          }) =>
              MealsCompanion(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            userId: userId,
            name: name,
            notes: notes,
          ),
          createCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            required String name,
            Value<String?> notes = const Value.absent(),
          }) =>
              MealsCompanion.insert(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            userId: userId,
            name: name,
            notes: notes,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$MealsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({mealItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (mealItemsRefs) db.mealItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (mealItemsRefs)
                    await $_getPrefetchedData<Meal, $MealsTable, MealItem>(
                        currentTable: table,
                        referencedTable:
                            $$MealsTableReferences._mealItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$MealsTableReferences(db, table, p0).mealItemsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.mealId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$MealsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MealsTable,
    Meal,
    $$MealsTableFilterComposer,
    $$MealsTableOrderingComposer,
    $$MealsTableAnnotationComposer,
    $$MealsTableCreateCompanionBuilder,
    $$MealsTableUpdateCompanionBuilder,
    (Meal, $$MealsTableReferences),
    Meal,
    PrefetchHooks Function({bool mealItemsRefs})>;
typedef $$MealItemsTableCreateCompanionBuilder = MealItemsCompanion Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required String mealId,
  Value<String?> productBarcode,
  Value<String?> productId,
  required int quantityInGrams,
});
typedef $$MealItemsTableUpdateCompanionBuilder = MealItemsCompanion Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> mealId,
  Value<String?> productBarcode,
  Value<String?> productId,
  Value<int> quantityInGrams,
});

final class $$MealItemsTableReferences
    extends BaseReferences<_$AppDatabase, $MealItemsTable, MealItem> {
  $$MealItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MealsTable _mealIdTable(_$AppDatabase db) => db.meals
      .createAlias($_aliasNameGenerator(db.mealItems.mealId, db.meals.id));

  $$MealsTableProcessedTableManager get mealId {
    final $_column = $_itemColumn<String>('meal_id')!;

    final manager = $$MealsTableTableManager($_db, $_db.meals)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mealIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias(
          $_aliasNameGenerator(db.mealItems.productId, db.products.id));

  $$ProductsTableProcessedTableManager? get productId {
    final $_column = $_itemColumn<String>('product_id');
    if ($_column == null) return null;
    final manager = $$ProductsTableTableManager($_db, $_db.products)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$MealItemsTableFilterComposer
    extends Composer<_$AppDatabase, $MealItemsTable> {
  $$MealItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productBarcode => $composableBuilder(
      column: $table.productBarcode,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quantityInGrams => $composableBuilder(
      column: $table.quantityInGrams,
      builder: (column) => ColumnFilters(column));

  $$MealsTableFilterComposer get mealId {
    final $$MealsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.mealId,
        referencedTable: $db.meals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MealsTableFilterComposer(
              $db: $db,
              $table: $db.meals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableFilterComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MealItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $MealItemsTable> {
  $$MealItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productBarcode => $composableBuilder(
      column: $table.productBarcode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quantityInGrams => $composableBuilder(
      column: $table.quantityInGrams,
      builder: (column) => ColumnOrderings(column));

  $$MealsTableOrderingComposer get mealId {
    final $$MealsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.mealId,
        referencedTable: $db.meals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MealsTableOrderingComposer(
              $db: $db,
              $table: $db.meals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableOrderingComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MealItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealItemsTable> {
  $$MealItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get productBarcode => $composableBuilder(
      column: $table.productBarcode, builder: (column) => column);

  GeneratedColumn<int> get quantityInGrams => $composableBuilder(
      column: $table.quantityInGrams, builder: (column) => column);

  $$MealsTableAnnotationComposer get mealId {
    final $$MealsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.mealId,
        referencedTable: $db.meals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MealsTableAnnotationComposer(
              $db: $db,
              $table: $db.meals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableAnnotationComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MealItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MealItemsTable,
    MealItem,
    $$MealItemsTableFilterComposer,
    $$MealItemsTableOrderingComposer,
    $$MealItemsTableAnnotationComposer,
    $$MealItemsTableCreateCompanionBuilder,
    $$MealItemsTableUpdateCompanionBuilder,
    (MealItem, $$MealItemsTableReferences),
    MealItem,
    PrefetchHooks Function({bool mealId, bool productId})> {
  $$MealItemsTableTableManager(_$AppDatabase db, $MealItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> mealId = const Value.absent(),
            Value<String?> productBarcode = const Value.absent(),
            Value<String?> productId = const Value.absent(),
            Value<int> quantityInGrams = const Value.absent(),
          }) =>
              MealItemsCompanion(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            mealId: mealId,
            productBarcode: productBarcode,
            productId: productId,
            quantityInGrams: quantityInGrams,
          ),
          createCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            required String mealId,
            Value<String?> productBarcode = const Value.absent(),
            Value<String?> productId = const Value.absent(),
            required int quantityInGrams,
          }) =>
              MealItemsCompanion.insert(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            mealId: mealId,
            productBarcode: productBarcode,
            productId: productId,
            quantityInGrams: quantityInGrams,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$MealItemsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({mealId = false, productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (mealId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.mealId,
                    referencedTable:
                        $$MealItemsTableReferences._mealIdTable(db),
                    referencedColumn:
                        $$MealItemsTableReferences._mealIdTable(db).id,
                  ) as T;
                }
                if (productId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.productId,
                    referencedTable:
                        $$MealItemsTableReferences._productIdTable(db),
                    referencedColumn:
                        $$MealItemsTableReferences._productIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$MealItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MealItemsTable,
    MealItem,
    $$MealItemsTableFilterComposer,
    $$MealItemsTableOrderingComposer,
    $$MealItemsTableAnnotationComposer,
    $$MealItemsTableCreateCompanionBuilder,
    $$MealItemsTableUpdateCompanionBuilder,
    (MealItem, $$MealItemsTableReferences),
    MealItem,
    PrefetchHooks Function({bool mealId, bool productId})>;
typedef $$FoodCategoriesTableCreateCompanionBuilder = FoodCategoriesCompanion
    Function({
  required String key,
  Value<String?> nameDe,
  Value<String?> nameEn,
  Value<String?> emoji,
  Value<int> rowid,
});
typedef $$FoodCategoriesTableUpdateCompanionBuilder = FoodCategoriesCompanion
    Function({
  Value<String> key,
  Value<String?> nameDe,
  Value<String?> nameEn,
  Value<String?> emoji,
  Value<int> rowid,
});

class $$FoodCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $FoodCategoriesTable> {
  $$FoodCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameDe => $composableBuilder(
      column: $table.nameDe, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameEn => $composableBuilder(
      column: $table.nameEn, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get emoji => $composableBuilder(
      column: $table.emoji, builder: (column) => ColumnFilters(column));
}

class $$FoodCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $FoodCategoriesTable> {
  $$FoodCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameDe => $composableBuilder(
      column: $table.nameDe, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameEn => $composableBuilder(
      column: $table.nameEn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get emoji => $composableBuilder(
      column: $table.emoji, builder: (column) => ColumnOrderings(column));
}

class $$FoodCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoodCategoriesTable> {
  $$FoodCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get nameDe =>
      $composableBuilder(column: $table.nameDe, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);
}

class $$FoodCategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FoodCategoriesTable,
    FoodCategory,
    $$FoodCategoriesTableFilterComposer,
    $$FoodCategoriesTableOrderingComposer,
    $$FoodCategoriesTableAnnotationComposer,
    $$FoodCategoriesTableCreateCompanionBuilder,
    $$FoodCategoriesTableUpdateCompanionBuilder,
    (
      FoodCategory,
      BaseReferences<_$AppDatabase, $FoodCategoriesTable, FoodCategory>
    ),
    FoodCategory,
    PrefetchHooks Function()> {
  $$FoodCategoriesTableTableManager(
      _$AppDatabase db, $FoodCategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String?> nameDe = const Value.absent(),
            Value<String?> nameEn = const Value.absent(),
            Value<String?> emoji = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FoodCategoriesCompanion(
            key: key,
            nameDe: nameDe,
            nameEn: nameEn,
            emoji: emoji,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            Value<String?> nameDe = const Value.absent(),
            Value<String?> nameEn = const Value.absent(),
            Value<String?> emoji = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FoodCategoriesCompanion.insert(
            key: key,
            nameDe: nameDe,
            nameEn: nameEn,
            emoji: emoji,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FoodCategoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FoodCategoriesTable,
    FoodCategory,
    $$FoodCategoriesTableFilterComposer,
    $$FoodCategoriesTableOrderingComposer,
    $$FoodCategoriesTableAnnotationComposer,
    $$FoodCategoriesTableCreateCompanionBuilder,
    $$FoodCategoriesTableUpdateCompanionBuilder,
    (
      FoodCategory,
      BaseReferences<_$AppDatabase, $FoodCategoriesTable, FoodCategory>
    ),
    FoodCategory,
    PrefetchHooks Function()>;
typedef $$FavoritesTableCreateCompanionBuilder = FavoritesCompanion Function({
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required String barcode,
  Value<int> rowid,
});
typedef $$FavoritesTableUpdateCompanionBuilder = FavoritesCompanion Function({
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> barcode,
  Value<int> rowid,
});

class $$FavoritesTableFilterComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnFilters(column));
}

class $$FavoritesTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnOrderings(column));
}

class $$FavoritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);
}

class $$FavoritesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FavoritesTable,
    Favorite,
    $$FavoritesTableFilterComposer,
    $$FavoritesTableOrderingComposer,
    $$FavoritesTableAnnotationComposer,
    $$FavoritesTableCreateCompanionBuilder,
    $$FavoritesTableUpdateCompanionBuilder,
    (Favorite, BaseReferences<_$AppDatabase, $FavoritesTable, Favorite>),
    Favorite,
    PrefetchHooks Function()> {
  $$FavoritesTableTableManager(_$AppDatabase db, $FavoritesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> barcode = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FavoritesCompanion(
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            barcode: barcode,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            required String barcode,
            Value<int> rowid = const Value.absent(),
          }) =>
              FavoritesCompanion.insert(
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            barcode: barcode,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FavoritesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FavoritesTable,
    Favorite,
    $$FavoritesTableFilterComposer,
    $$FavoritesTableOrderingComposer,
    $$FavoritesTableAnnotationComposer,
    $$FavoritesTableCreateCompanionBuilder,
    $$FavoritesTableUpdateCompanionBuilder,
    (Favorite, BaseReferences<_$AppDatabase, $FavoritesTable, Favorite>),
    Favorite,
    PrefetchHooks Function()>;
typedef $$DailyGoalsHistoryTableCreateCompanionBuilder
    = DailyGoalsHistoryCompanion Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required int targetCalories,
  required int targetProtein,
  required int targetCarbs,
  required int targetFat,
  required int targetWater,
  Value<int> targetSteps,
});
typedef $$DailyGoalsHistoryTableUpdateCompanionBuilder
    = DailyGoalsHistoryCompanion Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> targetCalories,
  Value<int> targetProtein,
  Value<int> targetCarbs,
  Value<int> targetFat,
  Value<int> targetWater,
  Value<int> targetSteps,
});

class $$DailyGoalsHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $DailyGoalsHistoryTable> {
  $$DailyGoalsHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetCalories => $composableBuilder(
      column: $table.targetCalories,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetProtein => $composableBuilder(
      column: $table.targetProtein, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetCarbs => $composableBuilder(
      column: $table.targetCarbs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetFat => $composableBuilder(
      column: $table.targetFat, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetWater => $composableBuilder(
      column: $table.targetWater, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetSteps => $composableBuilder(
      column: $table.targetSteps, builder: (column) => ColumnFilters(column));
}

class $$DailyGoalsHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyGoalsHistoryTable> {
  $$DailyGoalsHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetCalories => $composableBuilder(
      column: $table.targetCalories,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetProtein => $composableBuilder(
      column: $table.targetProtein,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetCarbs => $composableBuilder(
      column: $table.targetCarbs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetFat => $composableBuilder(
      column: $table.targetFat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetWater => $composableBuilder(
      column: $table.targetWater, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetSteps => $composableBuilder(
      column: $table.targetSteps, builder: (column) => ColumnOrderings(column));
}

class $$DailyGoalsHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyGoalsHistoryTable> {
  $$DailyGoalsHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get targetCalories => $composableBuilder(
      column: $table.targetCalories, builder: (column) => column);

  GeneratedColumn<int> get targetProtein => $composableBuilder(
      column: $table.targetProtein, builder: (column) => column);

  GeneratedColumn<int> get targetCarbs => $composableBuilder(
      column: $table.targetCarbs, builder: (column) => column);

  GeneratedColumn<int> get targetFat =>
      $composableBuilder(column: $table.targetFat, builder: (column) => column);

  GeneratedColumn<int> get targetWater => $composableBuilder(
      column: $table.targetWater, builder: (column) => column);

  GeneratedColumn<int> get targetSteps => $composableBuilder(
      column: $table.targetSteps, builder: (column) => column);
}

class $$DailyGoalsHistoryTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DailyGoalsHistoryTable,
    DailyGoalsHistoryData,
    $$DailyGoalsHistoryTableFilterComposer,
    $$DailyGoalsHistoryTableOrderingComposer,
    $$DailyGoalsHistoryTableAnnotationComposer,
    $$DailyGoalsHistoryTableCreateCompanionBuilder,
    $$DailyGoalsHistoryTableUpdateCompanionBuilder,
    (
      DailyGoalsHistoryData,
      BaseReferences<_$AppDatabase, $DailyGoalsHistoryTable,
          DailyGoalsHistoryData>
    ),
    DailyGoalsHistoryData,
    PrefetchHooks Function()> {
  $$DailyGoalsHistoryTableTableManager(
      _$AppDatabase db, $DailyGoalsHistoryTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyGoalsHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyGoalsHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyGoalsHistoryTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> targetCalories = const Value.absent(),
            Value<int> targetProtein = const Value.absent(),
            Value<int> targetCarbs = const Value.absent(),
            Value<int> targetFat = const Value.absent(),
            Value<int> targetWater = const Value.absent(),
            Value<int> targetSteps = const Value.absent(),
          }) =>
              DailyGoalsHistoryCompanion(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            targetCalories: targetCalories,
            targetProtein: targetProtein,
            targetCarbs: targetCarbs,
            targetFat: targetFat,
            targetWater: targetWater,
            targetSteps: targetSteps,
          ),
          createCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            required int targetCalories,
            required int targetProtein,
            required int targetCarbs,
            required int targetFat,
            required int targetWater,
            Value<int> targetSteps = const Value.absent(),
          }) =>
              DailyGoalsHistoryCompanion.insert(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            targetCalories: targetCalories,
            targetProtein: targetProtein,
            targetCarbs: targetCarbs,
            targetFat: targetFat,
            targetWater: targetWater,
            targetSteps: targetSteps,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DailyGoalsHistoryTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DailyGoalsHistoryTable,
    DailyGoalsHistoryData,
    $$DailyGoalsHistoryTableFilterComposer,
    $$DailyGoalsHistoryTableOrderingComposer,
    $$DailyGoalsHistoryTableAnnotationComposer,
    $$DailyGoalsHistoryTableCreateCompanionBuilder,
    $$DailyGoalsHistoryTableUpdateCompanionBuilder,
    (
      DailyGoalsHistoryData,
      BaseReferences<_$AppDatabase, $DailyGoalsHistoryTable,
          DailyGoalsHistoryData>
    ),
    DailyGoalsHistoryData,
    PrefetchHooks Function()>;
typedef $$SupplementSettingsHistoryTableCreateCompanionBuilder
    = SupplementSettingsHistoryCompanion Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required String supplementId,
  Value<bool> isTracked,
  required double dose,
  Value<double?> dailyGoal,
  Value<double?> dailyLimit,
});
typedef $$SupplementSettingsHistoryTableUpdateCompanionBuilder
    = SupplementSettingsHistoryCompanion Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> supplementId,
  Value<bool> isTracked,
  Value<double> dose,
  Value<double?> dailyGoal,
  Value<double?> dailyLimit,
});

final class $$SupplementSettingsHistoryTableReferences extends BaseReferences<
    _$AppDatabase,
    $SupplementSettingsHistoryTable,
    SupplementSettingsHistoryData> {
  $$SupplementSettingsHistoryTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $SupplementsTable _supplementIdTable(_$AppDatabase db) =>
      db.supplements.createAlias($_aliasNameGenerator(
          db.supplementSettingsHistory.supplementId, db.supplements.id));

  $$SupplementsTableProcessedTableManager get supplementId {
    final $_column = $_itemColumn<String>('supplement_id')!;

    final manager = $$SupplementsTableTableManager($_db, $_db.supplements)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_supplementIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$SupplementSettingsHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $SupplementSettingsHistoryTable> {
  $$SupplementSettingsHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isTracked => $composableBuilder(
      column: $table.isTracked, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get dose => $composableBuilder(
      column: $table.dose, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get dailyGoal => $composableBuilder(
      column: $table.dailyGoal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get dailyLimit => $composableBuilder(
      column: $table.dailyLimit, builder: (column) => ColumnFilters(column));

  $$SupplementsTableFilterComposer get supplementId {
    final $$SupplementsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.supplementId,
        referencedTable: $db.supplements,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SupplementsTableFilterComposer(
              $db: $db,
              $table: $db.supplements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SupplementSettingsHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $SupplementSettingsHistoryTable> {
  $$SupplementSettingsHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isTracked => $composableBuilder(
      column: $table.isTracked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get dose => $composableBuilder(
      column: $table.dose, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get dailyGoal => $composableBuilder(
      column: $table.dailyGoal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get dailyLimit => $composableBuilder(
      column: $table.dailyLimit, builder: (column) => ColumnOrderings(column));

  $$SupplementsTableOrderingComposer get supplementId {
    final $$SupplementsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.supplementId,
        referencedTable: $db.supplements,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SupplementsTableOrderingComposer(
              $db: $db,
              $table: $db.supplements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SupplementSettingsHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $SupplementSettingsHistoryTable> {
  $$SupplementSettingsHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get isTracked =>
      $composableBuilder(column: $table.isTracked, builder: (column) => column);

  GeneratedColumn<double> get dose =>
      $composableBuilder(column: $table.dose, builder: (column) => column);

  GeneratedColumn<double> get dailyGoal =>
      $composableBuilder(column: $table.dailyGoal, builder: (column) => column);

  GeneratedColumn<double> get dailyLimit => $composableBuilder(
      column: $table.dailyLimit, builder: (column) => column);

  $$SupplementsTableAnnotationComposer get supplementId {
    final $$SupplementsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.supplementId,
        referencedTable: $db.supplements,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SupplementsTableAnnotationComposer(
              $db: $db,
              $table: $db.supplements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SupplementSettingsHistoryTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SupplementSettingsHistoryTable,
    SupplementSettingsHistoryData,
    $$SupplementSettingsHistoryTableFilterComposer,
    $$SupplementSettingsHistoryTableOrderingComposer,
    $$SupplementSettingsHistoryTableAnnotationComposer,
    $$SupplementSettingsHistoryTableCreateCompanionBuilder,
    $$SupplementSettingsHistoryTableUpdateCompanionBuilder,
    (SupplementSettingsHistoryData, $$SupplementSettingsHistoryTableReferences),
    SupplementSettingsHistoryData,
    PrefetchHooks Function({bool supplementId})> {
  $$SupplementSettingsHistoryTableTableManager(
      _$AppDatabase db, $SupplementSettingsHistoryTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SupplementSettingsHistoryTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$SupplementSettingsHistoryTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SupplementSettingsHistoryTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> supplementId = const Value.absent(),
            Value<bool> isTracked = const Value.absent(),
            Value<double> dose = const Value.absent(),
            Value<double?> dailyGoal = const Value.absent(),
            Value<double?> dailyLimit = const Value.absent(),
          }) =>
              SupplementSettingsHistoryCompanion(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            supplementId: supplementId,
            isTracked: isTracked,
            dose: dose,
            dailyGoal: dailyGoal,
            dailyLimit: dailyLimit,
          ),
          createCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            required String supplementId,
            Value<bool> isTracked = const Value.absent(),
            required double dose,
            Value<double?> dailyGoal = const Value.absent(),
            Value<double?> dailyLimit = const Value.absent(),
          }) =>
              SupplementSettingsHistoryCompanion.insert(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            supplementId: supplementId,
            isTracked: isTracked,
            dose: dose,
            dailyGoal: dailyGoal,
            dailyLimit: dailyLimit,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SupplementSettingsHistoryTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({supplementId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (supplementId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.supplementId,
                    referencedTable: $$SupplementSettingsHistoryTableReferences
                        ._supplementIdTable(db),
                    referencedColumn: $$SupplementSettingsHistoryTableReferences
                        ._supplementIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$SupplementSettingsHistoryTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $SupplementSettingsHistoryTable,
        SupplementSettingsHistoryData,
        $$SupplementSettingsHistoryTableFilterComposer,
        $$SupplementSettingsHistoryTableOrderingComposer,
        $$SupplementSettingsHistoryTableAnnotationComposer,
        $$SupplementSettingsHistoryTableCreateCompanionBuilder,
        $$SupplementSettingsHistoryTableUpdateCompanionBuilder,
        (
          SupplementSettingsHistoryData,
          $$SupplementSettingsHistoryTableReferences
        ),
        SupplementSettingsHistoryData,
        PrefetchHooks Function({bool supplementId})>;
typedef $$HealthStepSegmentsTableCreateCompanionBuilder
    = HealthStepSegmentsCompanion Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required String provider,
  Value<String?> sourceId,
  required DateTime startAt,
  required DateTime endAt,
  required int stepCount,
  required String externalKey,
});
typedef $$HealthStepSegmentsTableUpdateCompanionBuilder
    = HealthStepSegmentsCompanion Function({
  Value<int> localId,
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> provider,
  Value<String?> sourceId,
  Value<DateTime> startAt,
  Value<DateTime> endAt,
  Value<int> stepCount,
  Value<String> externalKey,
});

class $$HealthStepSegmentsTableFilterComposer
    extends Composer<_$AppDatabase, $HealthStepSegmentsTable> {
  $$HealthStepSegmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get provider => $composableBuilder(
      column: $table.provider, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceId => $composableBuilder(
      column: $table.sourceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startAt => $composableBuilder(
      column: $table.startAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endAt => $composableBuilder(
      column: $table.endAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get stepCount => $composableBuilder(
      column: $table.stepCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get externalKey => $composableBuilder(
      column: $table.externalKey, builder: (column) => ColumnFilters(column));
}

class $$HealthStepSegmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $HealthStepSegmentsTable> {
  $$HealthStepSegmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get provider => $composableBuilder(
      column: $table.provider, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceId => $composableBuilder(
      column: $table.sourceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startAt => $composableBuilder(
      column: $table.startAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endAt => $composableBuilder(
      column: $table.endAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get stepCount => $composableBuilder(
      column: $table.stepCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get externalKey => $composableBuilder(
      column: $table.externalKey, builder: (column) => ColumnOrderings(column));
}

class $$HealthStepSegmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HealthStepSegmentsTable> {
  $$HealthStepSegmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<DateTime> get startAt =>
      $composableBuilder(column: $table.startAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endAt =>
      $composableBuilder(column: $table.endAt, builder: (column) => column);

  GeneratedColumn<int> get stepCount =>
      $composableBuilder(column: $table.stepCount, builder: (column) => column);

  GeneratedColumn<String> get externalKey => $composableBuilder(
      column: $table.externalKey, builder: (column) => column);
}

class $$HealthStepSegmentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HealthStepSegmentsTable,
    HealthStepSegment,
    $$HealthStepSegmentsTableFilterComposer,
    $$HealthStepSegmentsTableOrderingComposer,
    $$HealthStepSegmentsTableAnnotationComposer,
    $$HealthStepSegmentsTableCreateCompanionBuilder,
    $$HealthStepSegmentsTableUpdateCompanionBuilder,
    (
      HealthStepSegment,
      BaseReferences<_$AppDatabase, $HealthStepSegmentsTable, HealthStepSegment>
    ),
    HealthStepSegment,
    PrefetchHooks Function()> {
  $$HealthStepSegmentsTableTableManager(
      _$AppDatabase db, $HealthStepSegmentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HealthStepSegmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HealthStepSegmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HealthStepSegmentsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> provider = const Value.absent(),
            Value<String?> sourceId = const Value.absent(),
            Value<DateTime> startAt = const Value.absent(),
            Value<DateTime> endAt = const Value.absent(),
            Value<int> stepCount = const Value.absent(),
            Value<String> externalKey = const Value.absent(),
          }) =>
              HealthStepSegmentsCompanion(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            provider: provider,
            sourceId: sourceId,
            startAt: startAt,
            endAt: endAt,
            stepCount: stepCount,
            externalKey: externalKey,
          ),
          createCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            required String provider,
            Value<String?> sourceId = const Value.absent(),
            required DateTime startAt,
            required DateTime endAt,
            required int stepCount,
            required String externalKey,
          }) =>
              HealthStepSegmentsCompanion.insert(
            localId: localId,
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            provider: provider,
            sourceId: sourceId,
            startAt: startAt,
            endAt: endAt,
            stepCount: stepCount,
            externalKey: externalKey,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$HealthStepSegmentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $HealthStepSegmentsTable,
    HealthStepSegment,
    $$HealthStepSegmentsTableFilterComposer,
    $$HealthStepSegmentsTableOrderingComposer,
    $$HealthStepSegmentsTableAnnotationComposer,
    $$HealthStepSegmentsTableCreateCompanionBuilder,
    $$HealthStepSegmentsTableUpdateCompanionBuilder,
    (
      HealthStepSegment,
      BaseReferences<_$AppDatabase, $HealthStepSegmentsTable, HealthStepSegment>
    ),
    HealthStepSegment,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db, _db.exercises);
  $$RoutinesTableTableManager get routines =>
      $$RoutinesTableTableManager(_db, _db.routines);
  $$RoutineExercisesTableTableManager get routineExercises =>
      $$RoutineExercisesTableTableManager(_db, _db.routineExercises);
  $$RoutineSetTemplatesTableTableManager get routineSetTemplates =>
      $$RoutineSetTemplatesTableTableManager(_db, _db.routineSetTemplates);
  $$WorkoutLogsTableTableManager get workoutLogs =>
      $$WorkoutLogsTableTableManager(_db, _db.workoutLogs);
  $$SetLogsTableTableManager get setLogs =>
      $$SetLogsTableTableManager(_db, _db.setLogs);
  $$CardioActivitiesTableTableManager get cardioActivities =>
      $$CardioActivitiesTableTableManager(_db, _db.cardioActivities);
  $$CardioSamplesTableTableManager get cardioSamples =>
      $$CardioSamplesTableTableManager(_db, _db.cardioSamples);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$NutritionLogsTableTableManager get nutritionLogs =>
      $$NutritionLogsTableTableManager(_db, _db.nutritionLogs);
  $$SupplementsTableTableManager get supplements =>
      $$SupplementsTableTableManager(_db, _db.supplements);
  $$SupplementLogsTableTableManager get supplementLogs =>
      $$SupplementLogsTableTableManager(_db, _db.supplementLogs);
  $$FluidLogsTableTableManager get fluidLogs =>
      $$FluidLogsTableTableManager(_db, _db.fluidLogs);
  $$MeasurementsTableTableManager get measurements =>
      $$MeasurementsTableTableManager(_db, _db.measurements);
  $$PostsTableTableManager get posts =>
      $$PostsTableTableManager(_db, _db.posts);
  $$SocialInteractionsTableTableManager get socialInteractions =>
      $$SocialInteractionsTableTableManager(_db, _db.socialInteractions);
  $$MealsTableTableManager get meals =>
      $$MealsTableTableManager(_db, _db.meals);
  $$MealItemsTableTableManager get mealItems =>
      $$MealItemsTableTableManager(_db, _db.mealItems);
  $$FoodCategoriesTableTableManager get foodCategories =>
      $$FoodCategoriesTableTableManager(_db, _db.foodCategories);
  $$FavoritesTableTableManager get favorites =>
      $$FavoritesTableTableManager(_db, _db.favorites);
  $$DailyGoalsHistoryTableTableManager get dailyGoalsHistory =>
      $$DailyGoalsHistoryTableTableManager(_db, _db.dailyGoalsHistory);
  $$SupplementSettingsHistoryTableTableManager get supplementSettingsHistory =>
      $$SupplementSettingsHistoryTableTableManager(
          _db, _db.supplementSettingsHistory);
  $$HealthStepSegmentsTableTableManager get healthStepSegments =>
      $$HealthStepSegmentsTableTableManager(_db, _db.healthStepSegments);
}
