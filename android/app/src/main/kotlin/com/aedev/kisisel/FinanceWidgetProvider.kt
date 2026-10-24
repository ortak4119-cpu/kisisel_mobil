package com.aedev.kisisel

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
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

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java
                )
                setOnClickPendingIntent(R.id.widget_balance, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
