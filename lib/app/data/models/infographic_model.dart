class InfographicModel {
  final String htmlCode;
  final String cssCode;
  final String prompt;

  InfographicModel({
    required this.htmlCode,
    required this.cssCode,
    required this.prompt,
  });

  factory InfographicModel.fromJson(Map<String, dynamic> json) {
    return InfographicModel(
      htmlCode: json['html'] ?? '',
      cssCode: json['css'] ?? '',
      prompt: json['prompt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'html': htmlCode,
      'css': cssCode,
      'prompt': prompt,
    };
  }

  String get combinedHtml => '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Infographic</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        * {
            box-sizing: border-box;
        }
        
        body {
            margin: 0;
            padding: 0;
            width: 100vw;
            max-width: 100vw;
            overflow-x: hidden;
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        }
        
        img {
            max-width: 100%;
            height: auto;
            display: block;
        }
        
        $cssCode
    </style>
</head>
<body>
    $htmlCode
</body>
</html>
''';
}
