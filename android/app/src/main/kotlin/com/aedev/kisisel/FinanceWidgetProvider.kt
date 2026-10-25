package com.aedev.kisisel

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class FinanceWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.finance_widget).apply {
                setTextViewText(
                    R.id.widget_balance_label,
                    widgetData.getString("balance_label", "Kullanılabilir bakiye")
                )
                setTextViewText(
                    R.id.widget_balance,
                    widgetData.getString("balance", "—")
                )
                setTextViewText(
                    R.id.widget_spent,
                    widgetData.getString("spent", "—")
                )
                setTextViewText(
                    R.id.widget_income,
                    widgetData.getString("income", "—")
                )

                // Yeni Android sürümlerinde çöken HomeWidgetLaunchIntent yerine
                // PendingIntent'i elle kuruyoruz (bkz. NoteWidgetProvider).
                val launchIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_balance, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
