package com.texapp.atensia

/**
 * Medium (4×2) home screen widget receiver.
 *
 * Delegates all logic to [AtensiaWidgetProvider]; the separate class is
 * required so that Android can register it under a distinct provider info
 * XML (atensia_widget_medium_info) while reusing the same update logic.
 */
class AtensiaWidgetMediumProvider : AtensiaWidgetProvider()
