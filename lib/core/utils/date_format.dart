const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// Unambiguous display date, e.g. "Nov 8, 2026" (avoids d/m vs m/d confusion).
String formatLogosDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';
