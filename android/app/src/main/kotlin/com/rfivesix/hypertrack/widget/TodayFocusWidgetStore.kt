package com.rfivesix.hypertrack.widget

import android.content.Context
import com.rfivesix.hypertrack.R
import org.json.JSONArray
import org.json.JSONObject

data class TodayFocusWidgetRow(
    val key: String,
    val label: String,
    val valueText: String,
    val accentColor: Int,
)

data class TodayFocusWidgetPayload(
    val title: String,
    val subtitle: String,
    val emptyText: String,
    val enabled: Boolean,
    val maxVisibleItems: Int,
    val items: List<TodayFocusWidgetRow>,
) {
    companion object {
        fun empty(context: Context): TodayFocusWidgetPayload = TodayFocusWidgetPayload(
            title = context.getString(R.string.today_focus_widget_title),
            subtitle = "",
            emptyText = context.getString(R.string.today_focus_widget_empty),
            enabled = false,
            maxVisibleItems = 6,
            items = emptyList(),
        )

        fun fromJson(raw: String, context: Context): TodayFocusWidgetPayload {
            return try {
                val json = JSONObject(raw)
                val rows = mutableListOf<TodayFocusWidgetRow>()
                val itemsJson = json.optJSONArray("items") ?: JSONArray()
                for (i in 0 until itemsJson.length()) {
                    val item = itemsJson.optJSONObject(i) ?: continue
                    rows.add(
                        TodayFocusWidgetRow(
                            key = item.optString("key", ""),
                            label = item.optString("label", ""),
                            valueText = item.optString("valueText", ""),
                            accentColor = item.optInt("accentColor", 0xFF4CAF50.toInt()),
                        ),
                    )
                }
                TodayFocusWidgetPayload(
                    title = json.optString(
                        "title",
                        context.getString(R.string.today_focus_widget_title),
                    ),
                    subtitle = json.optString("subtitle", ""),
                    emptyText = json.optString(
                        "emptyText",
                        context.getString(R.string.today_focus_widget_empty),
                    ),
                    enabled = json.optBoolean("enabled", true),
                    maxVisibleItems = json.optInt("maxVisibleItems", 6),
                    items = rows,
                )
            } catch (_: Throwable) {
                empty(context)
            }
        }
    }
}

object TodayFocusWidgetStore {
    private const val prefsName = "today_focus_widget_prefs"
    private const val payloadKey = "payload_json"

    fun savePayload(context: Context, payloadJson: String) {
        context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
            .edit()
            .putString(payloadKey, payloadJson)
            .apply()
    }

    fun loadPayload(context: Context): TodayFocusWidgetPayload {
        val raw = context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
            .getString(payloadKey, null)
            ?: return TodayFocusWidgetPayload.empty(context)
        return TodayFocusWidgetPayload.fromJson(raw, context)
    }
}
