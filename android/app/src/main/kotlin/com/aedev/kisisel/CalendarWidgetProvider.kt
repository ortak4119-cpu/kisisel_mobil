package com.aedev.kisisel

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Ana ekran takvim widget'ı: bugünün ilk 3 etkinlik/görevini (başlık + saat)
 * gösterir. Veriler Flutter tarafında CalendarWidgetService ile yazılır
 * (home_widget).
 */
class CalendarWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.calendar_widget).apply {
                setTextViewText(R.id.cal_header, widgetData.getString("cal_header", "Bugün"))

                val count = widgetData.getInt("cal_count", 0)
                setViewVisibility(R.id.cal_empty, if (count == 0) View.VISIBLE else View.GONE)
                setTextViewText(R.id.cal_empty, widgetData.getString("cal_empty_text", "Bugün etkinlik yok"))

                val rows = intArrayOf(R.id.cal_row_1, R.id.cal_row_2, R.id.cal_row_3)
                val titles = intArrayOf(R.id.cal_title_1, R.id.cal_title_2, R.id.cal_title_3)
                val times = intArrayOf(R.id.cal_time_1, R.id.cal_time_2, R.id.cal_time_3)

                for (i in 0 until 3) {
                    if (i < count) {
                        setViewVisibility(rows[i], View.VISIBLE)
                        setTextViewText(titles[i], widgetData.getString("cal_title_${i + 1}", "—"))
                        setTextViewText(times[i], widgetData.getString("cal_time_${i + 1}", ""))
                    } else {
                        setViewVisibility(rows[i], View.GONE)
                    }
                }

                // home_widget 0.6.0 HomeWidgetLaunchIntent, API 34+ üzerinde
                // "pendingIntentBackgroundActivityStartMode" hatasıyla çöküyor;
                // bu yüzden PendingIntent'i elle kuruyoruz (NoteWidget ile aynı).
                val launchIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.cal_widget_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
