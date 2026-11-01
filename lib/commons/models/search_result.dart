/// One hit from `/vendor/search`, with the dashboard path it opens.
class SearchResult {
  final String group;
  final String title;
  final String subtitle;
  final String href;

  const SearchResult({
    required this.group,
    required this.title,
    required this.subtitle,
    required this.href,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
        group: json['group']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        subtitle: json['subtitle']?.toString() ?? '',
        href: json['href']?.toString() ?? '',
      );
}
