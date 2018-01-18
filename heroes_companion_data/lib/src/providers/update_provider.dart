import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:heroes_companion_data/src/api/DTO/update_info.dart';
import 'package:heroes_companion_data/src/api/DTO/update_payload.dart';
import 'package:sqflite/sqflite.dart';
import 'package:heroes_companion_data/src/tables/ability_table.dart'
    as ability_table;
import 'package:heroes_companion_data/src/tables/hero_table.dart' as hero_table;
import 'package:heroes_companion_data/src/tables/talent_table.dart'
    as talent_table;
import 'package:heroes_companion_data/src/api/api.dart' as api;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:heroes_companion_data/src/shared_preferences_keys.dart'
    as pref_keys;

class UpdateProvider {
  Database _database;
  UpdateProvider(this._database);

  Future<bool> doesNeedUpdate() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String unparsedId = (preferences.getString(pref_keys.update_id) ?? '');
    DateTime currentId =
        unparsedId == '' ? new DateTime(1970) : DateTime.parse(unparsedId);
    UpdateInfo updateInfo = await api.getUpdateInfo();
    return updateInfo.id.isAfter(currentId);
  }

  Future doUpdate() async {
    debugPrint('Doing Update!');
    UpdatePayload updatePayload = await api.getUpdate();

    // Hero Update
    updatePayload.heroes.forEach((hero) async {
      List<Map<String, dynamic>> existingHero = await _database.query(
          hero_table.table_name,
          columns: [hero_table.column_heroes_companion_hero_id],
          where: "${hero_table.column_hero_id} = ?",
          whereArgs: [hero.hero_id]);
      if (existingHero.isEmpty) {
        _database.insert(hero_table.table_name, hero.toUpdateMap());
      } else {
        await _database.update(hero_table.table_name, hero.toUpdateMap(),
            where: "${hero_table.column_heroes_companion_hero_id} = ?",
            whereArgs: [
              existingHero.first[hero_table.column_heroes_companion_hero_id]
            ]);
      }
    });

    // // Talent Update
    updatePayload.talents.forEach((talent) async {
      if (talent.hero_id == null) {
        debugPrint("${talent.name} has a null hero_id");
      }
      List<Map<String, dynamic>> existingTalent = await _database.query(
          talent_table.table_name,
          columns: [talent_table.column_id],
          where:
              "${talent_table.column_tool_tip_id} = ? AND ${talent_table.column_hero_id} = ?",
          whereArgs: [talent.tool_tip_id, talent.hero_id]);
      if (existingTalent.isEmpty) {
        _database.insert(talent_table.table_name, talent.toUpdateMap());
      } else {
        await _database.update(talent_table.table_name, talent.toUpdateMap(),
            where: "${talent_table.column_id} = ?",
            whereArgs: [existingTalent.first[talent_table.column_id]]);
      }
    });

    // // Ability Update
    updatePayload.abilities.forEach((ability) async {
      List<Map<String, dynamic>> existingAbility = await _database.query(
          ability_table.table_name,
          columns: [ability_table.column_id],
          where: "${ability_table.column_ability_id} = ?",
          whereArgs: [ability.ability_id]);
      if (existingAbility.isEmpty) {
        _database.insert(ability_table.table_name, ability.toUpdateMap());
      } else {
        await _database.update(ability_table.table_name, ability.toUpdateMap(),
            where: "${ability_table.column_id} = ?",
            whereArgs: [
              existingAbility.first[ability_table.column_ability_id]
            ]);
      }
    });

    SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.setString(pref_keys.update_id, updatePayload.id.toIso8601String());
  }
}