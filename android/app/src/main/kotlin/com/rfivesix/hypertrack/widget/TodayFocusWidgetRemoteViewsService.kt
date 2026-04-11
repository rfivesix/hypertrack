package com.rfivesix.hypertrack.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import com.rfivesix.hypertrack.R
import kotlin.math.max

class TodayFocusWidgetRemoteViewsService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return TodayFocusWidgetFactory(applicationContext, intent)
    }
}

class TodayFocusWidgetFactory(
    private val context: Context,
    intent: Intent,
) : RemoteViewsService.RemoteViewsFactory {
    private val appWidgetId: Int = intent.getIntExtra(
        AppWidgetManager.EXTRA_APPWIDGET_ID,
        AppWidgetManager.INVALID_APPWIDGET_ID,
    )

    private var rows: List<TodayFocusWidgetRow> = emptyList()

    override fun onCreate() = Unit

    override fun onDataSetChanged() {
        val payload = TodayFocusWidgetStore.loadPayload(context)
        if (!payload.enabled) {
            rows = emptyList()
            return
        }

        val manager = AppWidgetManager.getInstance(context)
        val options = manager.getAppWidgetOptions(appWidgetId)
        val minHeightDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)
        val minWidthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
        val sizeCap = computeSizeCap(minWidthDp = minWidthDp, minHeightDp = minHeightDp)
        val visible = max(1, minOf(payload.maxVisibleItems, sizeCap, payload.items.size))
        rows = payload.items.take(visible)
    }

    override fun onDestroy() {
        rows = emptyList()
    }

    override fun getCount(): Int = rows.size

    override fun getViewAt(position: Int): RemoteViews {
        val row = rows.getOrNull(position) ?: return RemoteViews(
            context.packageName,
            R.layout.today_focus_widget_row,
        )
        return RemoteViews(context.packageName, R.layout.today_focus_widget_row).apply {
            setTextViewText(R.id.today_focus_widget_row_label, row.label)
            setTextViewText(R.id.today_focus_widget_row_value, row.valueText)
            setInt(R.id.today_focus_widget_row_accent, "setBackgroundColor", row.accentColor)
        }
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long =
        rows.getOrNull(position)?.key?.hashCode()?.toLong() ?: position.toLong()

    override fun hasStableIds(): Boolean = true

    private fun computeSizeCap(minWidthDp: Int, minHeightDp: Int): Int {
        val safeMinHeight = max(1, minHeightDp)
        val safeMinWidth = max(1, minWidthDp)
        return when {
            safeMinHeight <= 110 -> 2
            safeMinHeight <= 170 -> 3
            safeMinHeight <= 240 -> 4
            safeMinHeight <= 320 -> 6
            safeMinWidth >= 280 -> 10
            else -> 8
        }
    }
}
