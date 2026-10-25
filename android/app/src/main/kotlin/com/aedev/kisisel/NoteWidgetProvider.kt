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
 * Ana ekran not widget'ı: en son 3 notun başlık + kısa içeriğini gösterir.
 * Veriler Flutter tarafında NoteWidgetService ile yazılır (home_widget).
 */
class NoteWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.note_widget).apply {
                val count = widgetData.getInt("note_count", 0)

                setViewVisibility(R.id.note_empty, if (count == 0) View.VISIBLE else View.GONE)

                val rows = intArrayOf(R.id.note_row_1, R.id.note_row_2, R.id.note_row_3)
                val titles = intArrayOf(R.id.note_title_1, R.id.note_title_2, R.id.note_title_3)
                val snips = intArrayOf(R.id.note_snip_1, R.id.note_snip_2, R.id.note_snip_3)

                for (i in 0 until 3) {
                    if (i < count) {
                        setViewVisibility(rows[i], View.VISIBLE)
                        setTextViewText(
                            titles[i],
                            widgetData.getString("note_title_${i + 1}", "—")
                        )
                        setTextViewText(
                            snips[i],
                            widgetData.getString("note_snip_${i + 1}", "")
                        )
                    } else {
                        setViewVisibility(rows[i], View.GONE)
                    }
                }

                // Not: home_widget 0.6.0 HomeWidgetLaunchIntent, yeni Android
                // sürümlerinde (API 34+) "pendingIntentBackgroundActivityStartMode"
                // hatasıyla çöküyor; bu yüzden PendingIntent'i elle kuruyoruz.
                val launchIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.note_widget_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
