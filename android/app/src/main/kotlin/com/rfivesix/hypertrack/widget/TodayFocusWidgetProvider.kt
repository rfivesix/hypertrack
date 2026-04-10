package com.rfivesix.hypertrack.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.rfivesix.hypertrack.MainActivity
import com.rfivesix.hypertrack.R

class TodayFocusWidgetProvider : AppWidgetProvider() {
    companion object {
        const val actionOpenDiaryFromWidget = "com.rfivesix.hypertrack.OPEN_DIARY_FROM_WIDGET"
        const val extraWidgetAction = "widget_action"
        const val widgetActionOpenDiary = "openDiary"

        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, TodayFocusWidgetProvider::class.java)
            val ids = manager.getAppWidgetIds(component)
            if (ids.isNotEmpty()) {
                manager.notifyAppWidgetViewDataChanged(ids, R.id.today_focus_widget_list)
                ids.forEach { id ->
                    updateWidget(context, manager, id)
                }
            }
        }

        private fun updateWidget(
            context: Context,
            manager: AppWidgetManager,
            appWidgetId: Int,
        ) {
            val payload = TodayFocusWidgetStore.loadPayload(context)
            val views = RemoteViews(context.packageName, R.layout.today_focus_widget)

            views.setTextViewText(R.id.today_focus_widget_title, payload.title)
            views.setTextViewText(R.id.today_focus_widget_subtitle, payload.subtitle)
            views.setTextViewText(R.id.today_focus_widget_empty, payload.emptyText)

            val serviceIntent = Intent(context, TodayFocusWidgetRemoteViewsService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                data = android.net.Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }
            views.setRemoteAdapter(R.id.today_focus_widget_list, serviceIntent)
            views.setEmptyView(R.id.today_focus_widget_list, R.id.today_focus_widget_empty)

            val launchIntent = Intent(context, MainActivity::class.java).apply {
                action = actionOpenDiaryFromWidget
                putExtra(extraWidgetAction, widgetActionOpenDiary)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.today_focus_widget_root, pendingIntent)

            manager.updateAppWidget(appWidgetId, views)
            manager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.today_focus_widget_list)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { appWidgetId ->
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle,
    ) {
        updateWidget(context, appWidgetManager, appWidgetId)
    }
}
