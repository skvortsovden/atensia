package com.texapp.atensia

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/**
 * Home screen widget provider for Атенція.
 *
 * Reads today's circumplex state and streak from SharedPreferences (written by
 * the Flutter side via the home_widget package) and renders it using one of two
 * layouts depending on the widget's declared minimum width:
 *   • small  (≤ 180 dp) → atensia_widget_small
 *   • medium (> 180 dp) → atensia_widget_medium
 *
 * Tapping any part of the widget opens the main activity.
 */
class AtensiaWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (id in appWidgetIds) {
            updateWidget(context, appWidgetManager, id)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
    ) {
        val prefs = context.getSharedPreferences("HomeWidgetPlugin", Context.MODE_PRIVATE)
        val quadrant     = prefs.getString("widget_quadrant", "")      ?: ""
        val streak       = prefs.getInt("widget_streak", 1)
        val valenceLabel = prefs.getString("widget_valence_label", "") ?: ""
        val arousalLabel = prefs.getString("widget_arousal_label", "") ?: ""
        val hasEntry     = prefs.getBoolean("widget_has_entry", false)

        // Choose layout based on declared minimum width (dp).
        val info = appWidgetManager.getAppWidgetInfo(appWidgetId)
        val isMedium = (info?.minWidth ?: 0) > 180
        val layoutId = if (isMedium) R.layout.atensia_widget_medium
                       else          R.layout.atensia_widget_small

        val views = RemoteViews(context.packageName, layoutId)

        val displayQuadrant = if (hasEntry && quadrant.isNotEmpty()) quadrant else "—"
        views.setTextViewText(R.id.widget_quadrant, displayQuadrant)
        views.setTextViewText(R.id.widget_streak, streak.toString())

        if (isMedium) {
            views.setTextViewText(
                R.id.widget_valence_label,
                if (valenceLabel.isNotEmpty()) valenceLabel else "—",
            )
            views.setTextViewText(
                R.id.widget_arousal_label,
                if (arousalLabel.isNotEmpty()) arousalLabel else "—",
            )
        }

        // Tap → open app.
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            context, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
