/// How a translation may be distributed in the app.
enum TranslationLicense {
  /// Public domain — free to use without notice.
  publicDomain,

  /// Openly licensed (e.g. CC BY-SA) — free to use with attribution.
  openLicense,

  /// Copyrighted; used under the publisher's quotation allowance with the
  /// required notice. A publisher licence is needed before commercial launch.
  publisherQuotation,
}

enum TranslationStyle {
  modern('Modern & readable'),
  formal('Word-for-word'),
  traditional('Traditional & historic'),
  literal('Strictly literal');

  final String label;
  const TranslationStyle(this.label);
}

class BibleTranslation {
  final String key;
  final String name;
  final TranslationStyle style;
  final String description;
  final TranslationLicense license;
  final String notice;

  const BibleTranslation({
    required this.key,
    required this.name,
    required this.style,
    required this.description,
    required this.license,
    required this.notice,
  });
}

/// Every translation offered in the app, in display order.
const List<BibleTranslation> bibleTranslations = [
  BibleTranslation(
    key: 'ESV',
    name: 'English Standard Version',
    style: TranslationStyle.formal,
    description: 'Literal yet readable, with literary cadence.',
    license: TranslationLicense.publisherQuotation,
    notice:
        'Scripture quotations are from the ESV® Bible (The Holy Bible, English Standard Version®), © 2001 by Crossway, a publishing ministry of Good News Publishers. Used by permission. All rights reserved.',
  ),
  BibleTranslation(
    key: 'NIV',
    name: 'New International Version',
    style: TranslationStyle.modern,
    description: 'Balanced, contemporary English.',
    license: TranslationLicense.publisherQuotation,
    notice:
        'Scripture quotations taken from The Holy Bible, New International Version® NIV®. Copyright © 1973, 1978, 1984, 2011 by Biblica, Inc.™ Used by permission. All rights reserved worldwide.',
  ),
  BibleTranslation(
    key: 'NASB',
    name: 'New American Standard Bible',
    style: TranslationStyle.formal,
    description: 'Strict formal equivalence, ideal for study.',
    license: TranslationLicense.publisherQuotation,
    notice:
        'Scripture quotations taken from the (NASB®) New American Standard Bible®, Copyright © 1960, 1971, 1977, 1995 by The Lockman Foundation. Used by permission. All rights reserved. lockman.org',
  ),
  BibleTranslation(
    key: 'KJV',
    name: 'King James Version',
    style: TranslationStyle.traditional,
    description: 'The historic 1611 text in Elizabethan English.',
    license: TranslationLicense.publicDomain,
    notice: 'King James Version — public domain (outside the United Kingdom).',
  ),
  BibleTranslation(
    key: 'BSB',
    name: 'Berean Standard Bible',
    style: TranslationStyle.modern,
    description: 'Clear, accurate modern English.',
    license: TranslationLicense.publicDomain,
    notice:
        'The Holy Bible, Berean Standard Bible (BSB). This text of God’s Word has been dedicated to the public domain.',
  ),
  BibleTranslation(
    key: 'WEB',
    name: 'World English Bible',
    style: TranslationStyle.modern,
    description: 'Modern update of the ASV.',
    license: TranslationLicense.publicDomain,
    notice: 'World English Bible — public domain.',
  ),
  BibleTranslation(
    key: 'LEB',
    name: 'Lexham English Bible',
    style: TranslationStyle.formal,
    description: 'Transparent to the original languages.',
    license: TranslationLicense.openLicense,
    notice:
        'Scripture quotations are from the Lexham English Bible. Copyright 2012 Logos Bible Software. Lexham is a registered trademark of Logos Bible Software.',
  ),
  BibleTranslation(
    key: 'BBE',
    name: 'Bible in Basic English',
    style: TranslationStyle.modern,
    description: 'Simple vocabulary, easy to read aloud.',
    license: TranslationLicense.publicDomain,
    notice: 'Bible in Basic English — public domain.',
  ),
  BibleTranslation(
    key: 'LSV',
    name: 'Literal Standard Version',
    style: TranslationStyle.literal,
    description: 'Highly literal modern translation.',
    license: TranslationLicense.openLicense,
    notice: 'Literal Standard Version © 2020 Covenant Press. Licensed CC BY-SA 4.0.',
  ),
  BibleTranslation(
    key: 'YLT',
    name: 'Young’s Literal Translation',
    style: TranslationStyle.literal,
    description: 'Follows the original word order (1898).',
    license: TranslationLicense.publicDomain,
    notice: 'Young’s Literal Translation — public domain.',
  ),
  BibleTranslation(
    key: 'ASV',
    name: 'American Standard Version',
    style: TranslationStyle.traditional,
    description: 'The 1901 American revision of the KJV.',
    license: TranslationLicense.publicDomain,
    notice: 'American Standard Version (1901) — public domain.',
  ),
  BibleTranslation(
    key: 'RV',
    name: 'Revised Version',
    style: TranslationStyle.traditional,
    description: 'The 1885 English revision of the KJV.',
    license: TranslationLicense.publicDomain,
    notice: 'Revised Version (1885) — public domain.',
  ),
  BibleTranslation(
    key: 'WBS',
    name: 'Webster Bible',
    style: TranslationStyle.traditional,
    description: 'Noah Webster’s 1833 KJV revision.',
    license: TranslationLicense.publicDomain,
    notice: 'Webster Bible (1833) — public domain.',
  ),
  BibleTranslation(
    key: 'DBY',
    name: 'Darby Translation',
    style: TranslationStyle.literal,
    description: 'J. N. Darby’s careful 1890 translation.',
    license: TranslationLicense.publicDomain,
    notice: 'Darby Translation (1890) — public domain.',
  ),
  BibleTranslation(
    key: 'GNV',
    name: 'Geneva Bible 1599',
    style: TranslationStyle.traditional,
    description: 'The Reformation-era Bible, original spelling.',
    license: TranslationLicense.publicDomain,
    notice: 'Geneva Bible (1599) — public domain.',
  ),
  BibleTranslation(
    key: 'DRA',
    name: 'Douay-Rheims',
    style: TranslationStyle.traditional,
    description: 'Historic Catholic English translation.',
    license: TranslationLicense.publicDomain,
    notice: 'Douay-Rheims Bible (1899 American edition) — public domain.',
  ),
];

BibleTranslation? translationByKey(String key) {
  for (final t in bibleTranslations) {
    if (t.key == key) return t;
  }
  return null;
}
