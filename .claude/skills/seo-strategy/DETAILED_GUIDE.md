# SEO Strategy — Detailed Implementation Guide

## SeoWrapper Implementation

```dart
// lib/core/seo/seo_wrapper.dart
import 'dart:js_interop';
import 'package:flutter/material.dart';

@JS('document.title')
external set _documentTitle(String value);

@JS('document.querySelector')
external JSObject? _querySelector(String selector);

class SeoWrapper extends StatefulWidget {
  final String title;
  final String description;
  final List<String> keywords;
  final Map<String, dynamic>? structuredData;
  final Widget child;

  const SeoWrapper({
    super.key,
    required this.title,
    required this.description,
    this.keywords = const [],
    this.structuredData,
    required this.child,
  });

  @override
  State<SeoWrapper> createState() => _SeoWrapperState();
}

class _SeoWrapperState extends State<SeoWrapper> {
  @override
  void initState() {
    super.initState();
    _applyMeta();
  }

  @override
  void didUpdateWidget(SeoWrapper old) {
    super.didUpdateWidget(old);
    if (old.title != widget.title || old.description != widget.description) {
      _applyMeta();
    }
  }

  void _applyMeta() {
    // Set document title
    _documentTitle = widget.title;
    // Meta tags are set via index.html for pre-render;
    // for SPAs, use your preferred meta tag JS interop approach.
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
```

## JSON-LD Structured Data Templates

### Organization
```dart
final organizationSchema = {
  '@context': 'https://schema.org',
  '@type': 'Organization',
  'name': 'Ras3uCat',
  'url': 'https://yoursite.com',
  'logo': 'https://yoursite.com/assets/logo.png',
  'sameAs': [
    'https://twitter.com/yourhandle',
    'https://github.com/yourhandle',
  ],
};
```

### SoftwareApplication
```dart
final appSchema = {
  '@context': 'https://schema.org',
  '@type': 'SoftwareApplication',
  'name': 'App Name',
  'operatingSystem': 'Web, Android, iOS',
  'applicationCategory': 'UtilitiesApplication',
  'offers': {
    '@type': 'Offer',
    'price': '9.99',
    'priceCurrency': 'USD',
  },
  'aggregateRating': {
    '@type': 'AggregateRating',
    'ratingValue': '4.8',
    'ratingCount': '240',
  },
};
```

### FAQ Page
```dart
Map<String, dynamic> faqSchema(List<Map<String, String>> faqs) => {
  '@context': 'https://schema.org',
  '@type': 'FAQPage',
  'mainEntity': faqs.map((faq) => {
    '@type': 'Question',
    'name': faq['question'],
    'acceptedAnswer': {
      '@type': 'Answer',
      'text': faq['answer'],
    },
  }).toList(),
};
```

## web/index.html Meta Setup

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">

  <!-- Default meta (overridden per-route via JS) -->
  <title>Ras3uCat — Retro-Futuristic Tactical Apps</title>
  <meta name="description" content="Default site description under 155 characters.">
  <meta name="keywords" content="flutter app, getx, supabase">

  <!-- Open Graph -->
  <meta property="og:type" content="website">
  <meta property="og:url" content="https://yoursite.com">
  <meta property="og:title" content="Ras3uCat">
  <meta property="og:description" content="Default OG description.">
  <meta property="og:image" content="https://yoursite.com/assets/og-image.png">

  <!-- Twitter Card -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="Ras3uCat">
  <meta name="twitter:description" content="Default Twitter description.">
  <meta name="twitter:image" content="https://yoursite.com/assets/og-image.png">

  <!-- Canonical -->
  <link rel="canonical" href="https://yoursite.com">
</head>
```

## Sitemap Generation (Dart Script)

```dart
// scripts/generate_sitemap.dart
// Run with: dart run scripts/generate_sitemap.dart

import 'dart:io';

void main() {
  final routes = [
    ('/', 1.0, 'daily'),
    ('/features', 0.9, 'weekly'),
    ('/pricing', 0.8, 'monthly'),
    ('/about', 0.5, 'monthly'),
  ];

  final now = DateTime.now().toIso8601String().substring(0, 10);
  final buffer = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">');

  for (final (path, priority, changefreq) in routes) {
    buffer
      ..writeln('  <url>')
      ..writeln('    <loc>https://yoursite.com$path</loc>')
      ..writeln('    <lastmod>$now</lastmod>')
      ..writeln('    <changefreq>$changefreq</changefreq>')
      ..writeln('    <priority>$priority</priority>')
      ..writeln('  </url>');
  }

  buffer.writeln('</urlset>');

  File('web/sitemap.xml').writeAsStringSync(buffer.toString());
  print('✅ sitemap.xml generated');
}
```

## web/robots.txt
```
User-agent: *
Allow: /
Disallow: /api/
Disallow: /admin/
Disallow: /auth/

Sitemap: https://yoursite.com/sitemap.xml
```

## Page SEO Checklist
Before any public page ships:
- [ ] Unique title (50–60 chars) set via SeoWrapper
- [ ] Unique description (130–155 chars)
- [ ] Relevant keywords (5–10, no stuffing)
- [ ] Canonical URL set
- [ ] OG image 1200×630px exists
- [ ] Structured data validated at schema.org/validator
- [ ] Page in sitemap.xml
- [ ] No auth/private routes accessible without login
