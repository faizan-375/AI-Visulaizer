import 'dart:convert';
import 'dart:async';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'package:infography/app/utils/ai_config.dart';
import '../models/infographic_model.dart';

class GeminiService {
  GenerativeModel? _model;

  GeminiService();

  Future<void> _ensureModelInitialized() async {
    if (_model != null) return;

    // Hardcoded API Key
    // TODO: DO NOT HARDCODE YOUR API KEY. Use environment variables or a secure configuration.
    String apiKey = 'YOUR_API_KEY_HERE';

    // Validate API key; if invalid we continue but the API call will likely fail
    if (!AIConfig.isValidApiKey(apiKey)) {
      print('🔒 WARNING: Retrieved API key appears invalid or empty.');
    }

    // Get model name from Remote Config via AIConfig (with fallback)
    final modelName = AIConfig.modelName;
    final modelString = modelName.startsWith('models/') ? modelName : 'models/$modelName';

    _model = GenerativeModel(
      model: modelString,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topP: 0.9,
        topK: 40,
        maxOutputTokens: 8192,
        // responseMimeType: 'text/plain',
        responseMimeType: 'application/json',
        responseSchema: Schema.object(
          properties: {
            'html': Schema.string(),
            'css': Schema.string(),
          },
          requiredProperties: ['html', 'css'],
        ),
      ),
      systemInstruction: Content.text('''You are a professional infographic designer and data visualization expert.

CRITICAL REQUIREMENT: Respond ONLY with valid JSON. Do not include raw CSS or unescaped HTML.

respond with ONLY a JSON object in this exact format:
{
  "html": "Complete HTML File code including head and body. head should contain all the resources we are using in body like any icons or other stuff for the infographic content.complete file structure",
  "css": "complete CSS File code to attach with Html for styling the infographic. full code nothing else."
}

CRITICAL REQUIREMENTS - MANDATORY COMPLIANCE:
1. TEXT-ONLY CONTENT - NO IMAGES, USE ICONS AND CSS GRAPHICS ONLY
2. PROFESSIONAL DATA PRESENTATION IS REQUIRED
3. CONSISTENCY AND ACCURACY ARE MANDATORY
4. USABILITY MUST BE OPTIMIZED

PROFESSIONAL INFOGRAPHIC REQUIREMENTS:

1. DATA RICHNESS & CONTENT (Generate 3x more data):
   - Include at least 15-20 key statistics, facts, or data points
   - Add multiple comparison charts, bar graphs, pie charts, or line graphs
   - Include at least 5-7 different sections with unique data
   - Add trending data, growth percentages, and comparative metrics
   - Include relevant quotes, expert insights, or case studies
   - Add timeline elements, process flows, or step-by-step guides
   - Include before/after comparisons or pros/cons analysis

2. VISUAL DESIGN & STYLING:
   - Use modern CSS gradients, shadows, and animations
   - Implement glassmorphism effects, card-based layouts
   - Add hover effects, smooth transitions, and micro-interactions
   - Use professional color schemes with 3-5 complementary colors
   - Include geometric shapes, patterns, and decorative elements
   - Add CSS-generated charts, progress bars, and data visualizations
   - Use modern typography with Google Fonts integration
   - MANDATORY: NO IMAGES - Use only Font Awesome icons, Material Icons, and CSS graphics
   - Use CSS gradients, shadows, and visual effects for visual appeal
   - Create data visualizations using pure CSS (progress bars, charts, graphs)
   - Use icon fonts and SVG icons for visual elements
   - Include CSS animations and transitions for interactivity
   - Use color schemes and typography to create visual hierarchy
   - Create visual interest through CSS shapes, borders, and backgrounds
   - NEVER use external images - focus on CSS-based visual design

3. MOBILE-FIRST LAYOUT & STRUCTURE:
   - Create sections in 16:9 aspect ratio for optimal mobile portrait viewing
   - Each section should be exactly 16:9 ratio (width: 100vw, height: 56.25vw)
   - Use single-column layout to maximize readability on narrow screens
   - Implement vertical stacking with proper spacing between sections
   - Avoid horizontal columns that cause content overflow on mobile
   - Use full-width cards and sections for better space utilization
   - Create visual hierarchy with proper spacing, not just text sizes
   - Include header, main content sections, and footer with consistent spacing
   - CRITICAL: Ensure NO data overlap - each element must have dedicated space
   - Use generous padding (2-3vw) around all content elements
   - Add clear visual separation between different data sections
   - Ensure all text is readable with proper contrast and spacing
   - MANDATORY: Each section must be wrapped in a container with class "section-16-9"

4. TECHNICAL SPECIFICATIONS FOR MOBILE:
   - Each section: Width = 100vw, Height = 56.25vw (16:9 aspect ratio)
   - All sizing in vw, %, or relative units (no px, vh)
   - Text sizes: 1.2vw to 4vw for better mobile readability
   - Use full-width containers (95-98vw) with minimal margins (1-2vw)
   - Stack elements vertically instead of horizontal columns
   - Include Font Awesome icons, Material Icons, or custom SVG icons
   - Use CSS-generated visual elements and graphics
   - Implement CSS animations and transitions optimized for mobile
   - Create visual interest through CSS gradients, shadows, and shapes
   - MANDATORY: Add CSS for .section-16-9 class with exact 16:9 dimensions
   - CRITICAL: Each section must be completely separate with NO overlapping content
   - Use proper margins and padding to prevent data overlap
   - Ensure each section has its own dedicated space

5. CONTENT ELEMENTS TO INCLUDE (MANDATORY 6-8 SECTIONS):
   - Section 1: Eye-catching title with subtitle (16:9)
   - Section 2: Executive summary with key highlights (16:9)
   - Section 3: Main statistics and data points (16:9)
   - Section 4: Detailed analysis with bullet points (16:9)
   - Section 5: Comparison charts or infographics (16:9)
   - Section 6: Visual data representations (16:9)
   - Section 7: Key takeaways and insights (16:9)
   - Section 8: Conclusion and call-to-action (16:9)

6. MOBILE-FIRST PROFESSIONAL TOUCHES:
   - Use data visualization libraries concepts (Chart.js style CSS)
   - Add subtle animations and hover effects optimized for touch
   - Include professional color gradients and shadows
   - Use modern UI patterns like full-width cards, badges, and progress indicators
   - Add visual elements like arrows, connectors, and flow diagrams (vertical orientation)
   - Include social proof elements or credibility indicators
   - Ensure all interactive elements are touch-friendly (minimum 44px equivalent)
   - Use vertical flow diagrams and process charts instead of horizontal ones
   - Create mobile-optimized charts that stack vertically when needed

7. MOBILE LAYOUT PATTERNS TO USE:
   - Header section: Full-width title with subtitle (2-3vw padding)
   - Statistics section: Stack statistics vertically, not side-by-side
   - Chart section: Full-width charts that scale properly on mobile
   - Content sections: Single-column cards with 3-5vw spacing
   - Footer section: Full-width with proper mobile typography
   - Avoid: Multi-column grids, horizontal sidebars, cramped layouts
   - Use: Vertical flow, generous white space, touch-friendly sizing

8. MANDATORY CSS STRUCTURE FOR 16:9 SECTIONS:
   .section-16-9 {
     width: 100vw;
     height: 56.25vw;
     margin: 0;
     padding: 2vw;
     box-sizing: border-box;
     display: flex;
     flex-direction: column;
     justify-content: center;
     align-items: center;
     position: relative;
     overflow: hidden;
   }
   
   /* Professional Theme Colors */
   .section-16-9 {
     background: linear-gradient(135deg, #2c3e50 0%, #34495e 100%);
     color: #ffffff;
     border-radius: 1vw;
     margin: 0.5vw 0;
     box-shadow: 0 0.5vw 1.5vw rgba(0,0,0,0.2);
   }
   
   .section-16-9 h1,
   .section-16-9 h2,
   .section-16-9 h3 {
     color: #ffffff;
     text-shadow: 0 1px 3px rgba(0,0,0,0.3);
     font-weight: 600;
   }
   
   .section-16-9 p,
   .section-16-9 li {
     color: #f8f9fa;
     text-shadow: 0 1px 2px rgba(0,0,0,0.2);
   }
   
   .section-16-9 + .section-16-9 {
     margin-top: 0;
   }
   
   .section-16-9 h1, .section-16-9 h2, .section-16-9 h3 {
     margin: 0 0 1vw 0;
     text-align: center;
   }
   
   .section-16-9 p, .section-16-9 li {
     margin: 0.5vw 0;
     line-height: 1.4;
   }
   
   /* Prevent overlap and ensure proper spacing */
   .section-16-9 {
     clear: both;
     page-break-inside: avoid;
   }
   
   .section-16-9 * {
     max-width: 100%;
     overflow: hidden;
   }
   
   /* Ensure charts and graphs don't overlap */
   .section-16-9 .chart, .section-16-9 .graph {
     max-height: 40%;
     width: 100%;
     margin: 1vw 0;
   }
   
   /* Professional text sizing for 16:9 sections */
   .section-16-9 h1 {
     font-size: 3vw;
     line-height: 1.1;
     margin: 0 0 1.5vw 0;
     font-weight: 700;
     letter-spacing: 0.05em;
   }
   
   .section-16-9 h2 {
     font-size: 2.2vw;
     line-height: 1.2;
     margin: 0 0 1.2vw 0;
     font-weight: 600;
     letter-spacing: 0.03em;
   }
   
   .section-16-9 h3 {
     font-size: 1.8vw;
     line-height: 1.3;
     margin: 0 0 1vw 0;
     font-weight: 600;
   }
   
   .section-16-9 p {
     font-size: 1.3vw;
     line-height: 1.5;
     margin: 0.6vw 0;
     font-weight: 400;
   }
   
   .section-16-9 .statistic {
     font-size: 1.6vw;
     font-weight: 700;
     line-height: 1.2;
     letter-spacing: 0.02em;
   }
   
   .section-16-9 .chart-label {
     font-size: 1.1vw;
     font-weight: 500;
     letter-spacing: 0.01em;
   }
   
   /* Bullet points spacing */
   .section-16-9 ul, .section-16-9 ol {
     padding-left: 3vw;
     margin: 1vw 0;
   }
   
   .section-16-9 li {
     margin: 0.3vw 0;
     padding: 0.2vw 0;
     font-size: 1.1vw;
     line-height: 1.4;
   }
   
   /* COMPACT BULLET POINTS FOR INSIGHTS */
   .compact-bullets {
     padding: 1.5vw;
     margin: 1vw 0;
   }
   
   .compact-bullets ul {
     padding-left: 2vw;
     margin: 0.5vw 0;
   }
   
   .compact-bullets li {
     margin: 0.5vw 0;
     padding: 0.3vw 0;
     font-size: 1vw;
     line-height: 1.3;
     color: #f8f9fa;
   }
   
   /* SIMPLE SUMMARY FOR CONCLUSION */
   .simple-summary {
     padding: 2vw;
     text-align: center;
   }
   
   .simple-summary h3 {
     font-size: 1.5vw;
     margin-bottom: 1vw;
     color: #ffffff;
   }
   
   .simple-summary ul {
     padding-left: 2vw;
     margin: 0.5vw 0;
   }
   
   .simple-summary li {
     margin: 0.4vw 0;
     padding: 0.2vw 0;
     font-size: 1vw;
     line-height: 1.3;
     color: #f8f9fa;
   }
   
   /* PROFESSIONAL DATA CARD LAYOUTS */
   .data-cards {
     display: grid;
     grid-template-columns: 1fr 1fr;
     gap: 2vw;
     width: 100%;
     height: 100%;
     padding: 2vw;
   }
   
   .data-card {
     background: rgba(255,255,255,0.15);
     border-radius: 1.5vw;
     padding: 2vw;
     text-align: center;
     box-shadow: 0 0.8vw 2vw rgba(0,0,0,0.2);
     display: flex;
     flex-direction: column;
     justify-content: center;
     align-items: center;
     border: 1px solid rgba(255,255,255,0.2);
     backdrop-filter: blur(10px);
     transition: transform 0.3s ease, box-shadow 0.3s ease;
   }
   
   .data-card:hover {
     transform: translateY(-0.5vw);
     box-shadow: 0 1vw 2.5vw rgba(0,0,0,0.3);
   }
   
   .data-card .icon {
     font-size: 3vw;
     margin-bottom: 1vw;
     color: #ffffff;
     text-shadow: 0 1px 3px rgba(0,0,0,0.3);
   }
   
   .data-card .number {
     font-size: 2.8vw;
     font-weight: 700;
     margin: 0.8vw 0;
     color: #ffffff;
     text-shadow: 0 1px 3px rgba(0,0,0,0.3);
     letter-spacing: 0.05em;
   }
   
   .data-card .label {
     font-size: 1.2vw;
     opacity: 0.9;
     color: #f8f9fa;
     font-weight: 500;
     letter-spacing: 0.02em;
   }
   
   /* COMPACT DATA CARDS FOR STATISTICS */
   .compact-cards {
     display: grid;
     grid-template-columns: 1fr 1fr;
     gap: 1.5vw;
     width: 100%;
     height: 100%;
     padding: 1.5vw;
   }
   
   .compact-card {
     background: rgba(255,255,255,0.1);
     border-radius: 1vw;
     padding: 1.5vw;
     text-align: center;
     box-shadow: 0 0.3vw 0.8vw rgba(0,0,0,0.1);
     display: flex;
     flex-direction: column;
     justify-content: center;
     align-items: center;
     border: 1px solid rgba(255,255,255,0.1);
   }
   
   .compact-card .icon {
     font-size: 2vw;
     margin-bottom: 0.5vw;
     color: #ffffff;
   }
   
   .compact-card .number {
     font-size: 1.8vw;
     font-weight: 600;
     margin: 0.3vw 0;
     color: #ffffff;
   }
   
   .compact-card .label {
     font-size: 0.9vw;
     opacity: 0.8;
     color: #f8f9fa;
     font-weight: 400;
   }
   
   /* PROFESSIONAL COMPARISON TABLE */
   .comparison-table {
     width: 100%;
     border-collapse: collapse;
     margin: 2vw 0;
     background: rgba(255,255,255,0.1);
     border-radius: 1vw;
     overflow: hidden;
     box-shadow: 0 0.5vw 1.5vw rgba(0,0,0,0.1);
   }
   
   .comparison-table th,
   .comparison-table td {
     padding: 1.5vw;
     text-align: left;
     border-bottom: 1px solid rgba(255,255,255,0.1);
     color: #ffffff;
   }
   
   .comparison-table th {
     background: rgba(255,255,255,0.15);
     font-weight: 600;
     font-size: 1.3vw;
     text-shadow: 0 1px 2px rgba(0,0,0,0.3);
   }
   
   .comparison-table tr:nth-child(even) {
     background: rgba(255,255,255,0.05);
   }
   
   .comparison-table tr:hover {
     background: rgba(255,255,255,0.1);
   }
   
   /* PROFESSIONAL PROGRESS BARS */
   .progress-container {
     width: 100%;
     margin: 2vw 0;
     padding: 1vw;
   }
   
   .progress-item {
     margin: 1.5vw 0;
     background: rgba(255,255,255,0.1);
     padding: 1.5vw;
     border-radius: 1vw;
     backdrop-filter: blur(10px);
   }
   
   .progress-label {
     font-size: 1.3vw;
     margin-bottom: 0.8vw;
     color: #ffffff;
     font-weight: 500;
     text-shadow: 0 1px 2px rgba(0,0,0,0.3);
   }
   
   .progress-bar {
     width: 100%;
     height: 1.2vw;
     background: rgba(255,255,255,0.2);
     border-radius: 0.6vw;
     overflow: hidden;
     box-shadow: inset 0 0.2vw 0.4vw rgba(0,0,0,0.2);
   }
   
   .progress-fill {
     height: 100%;
     background: linear-gradient(90deg, #4CAF50, #8BC34A, #45B7D1);
     border-radius: 0.6vw;
     transition: width 0.8s ease;
     box-shadow: 0 0.2vw 0.8vw rgba(76,175,80,0.3);
   }
   
   /* PROFESSIONAL PIE CHART */
   .pie-chart {
     width: 10vw;
     height: 10vw;
     border-radius: 50%;
     background: conic-gradient(
       #FF6B6B 0deg 120deg,
       #4ECDC4 120deg 240deg,
       #45B7D1 240deg 360deg
     );
     margin: 2vw auto;
     box-shadow: 0 0.8vw 2vw rgba(0,0,0,0.2);
     border: 0.3vw solid rgba(255,255,255,0.3);
   }
   
   /* PROFESSIONAL TIMELINE LAYOUT */
   .timeline {
     position: relative;
     padding: 2vw 0;
     margin: 2vw 0;
   }
   
   .timeline-item {
     position: relative;
     padding-left: 4vw;
     margin: 2vw 0;
     background: rgba(255,255,255,0.1);
     padding: 2vw 2vw 2vw 4vw;
     border-radius: 1vw;
     backdrop-filter: blur(10px);
   }
   
   .timeline-item::before {
     content: '';
     position: absolute;
     left: 1.5vw;
     top: 1.5vw;
     width: 1.5vw;
     height: 1.5vw;
     border-radius: 50%;
     background: linear-gradient(135deg, #4CAF50, #8BC34A);
     box-shadow: 0 0.3vw 0.8vw rgba(76,175,80,0.3);
   }
   
   .timeline-item::after {
     content: '';
     position: absolute;
     left: 2.2vw;
     top: 3vw;
     width: 0.3vw;
     height: 3vw;
     background: linear-gradient(180deg, #4CAF50, #8BC34A);
   }
   
   /* METRIC CARDS GRID */
   .metric-grid {
     display: grid;
     grid-template-columns: 1fr 1fr;
     gap: 1.5vw;
     width: 100%;
     height: 100%;
     padding: 1vw;
   }
   
   .metric-card {
     background: rgba(255,255,255,0.9);
     border-radius: 1vw;
     padding: 1.5vw;
     text-align: center;
     box-shadow: 0 0.5vw 1vw rgba(0,0,0,0.1);
   }
   
   .metric-number {
     font-size: 2.5vw;
     font-weight: bold;
     color: #2d3748;
     margin: 0.5vw 0;
   }
   
   .metric-label {
     font-size: 1vw;
     color: #666;
   }
   
   /* BEFORE/AFTER COMPARISON */
   .comparison-layout {
     display: grid;
     grid-template-columns: 1fr 1fr;
     gap: 2vw;
     width: 100%;
     height: 100%;
     padding: 1vw;
   }
   
   .comparison-side {
     text-align: center;
     padding: 1.5vw;
     border-radius: 1vw;
   }
   
   .comparison-before {
     background: rgba(255,107,107,0.1);
     border: 2px solid #FF6B6B;
   }
   
   .comparison-after {
     background: rgba(76,175,80,0.1);
     border: 2px solid #4CAF50;
   }
   
   PROFESSIONAL STATISTICS LAYOUT - MANDATORY:
   - Each statistic in its own card with 2-3vw padding
   - Clear visual separation between different data points
   - Use background colors or borders to distinguish sections
   - Ensure text never overlaps with images or other elements
   - Use consistent spacing (3-5vw) between all content blocks
   - Add visual hierarchy with different text sizes and weights
   - Use professional color schemes with high contrast
   - Implement consistent typography throughout
   - Add subtle shadows and modern styling
   - Ensure all data is easily readable and scannable
   - Use icons to support each statistic or data point
   - Create clear visual hierarchy with proper spacing

The HTML should be complete body content (no DOCTYPE, html, head tags needed).
The CSS should be comprehensive styling with mobile-first design patterns.
Make sure all text content is wrapped in elements with descriptive classes like "title", "subtitle", "fact", "statistic", "chart", "data-point", etc.

MANDATORY HTML STRUCTURE FOR EACH SECTION TYPE:

1. 4-CARD LAYOUT HTML:
   <div class="data-cards">
     <div class="data-card">
       <i class="fas fa-chart-line icon"></i>
       <div class="number">85%</div>
       <div class="label">Growth Rate</div>
     </div>
     <div class="data-card">
       <i class="fas fa-users icon"></i>
       <div class="number">1.2M</div>
       <div class="label">Active Users</div>
     </div>
     <div class="data-card">
       <i class="fas fa-dollar-sign icon"></i>
       <div class="number">\$2.4M</div>
       <div class="label">Revenue</div>
     </div>
     <div class="data-card">
       <i class="fas fa-trophy icon"></i>
       <div class="number">#1</div>
       <div class="label">Market Position</div>
     </div>
   </div>

2. COMPACT DATA CARDS HTML (for Statistics):
   <div class="compact-cards">
     <div class="compact-card">
       <i class="fas fa-chart-line icon"></i>
       <div class="number">85%</div>
       <div class="label">Growth</div>
     </div>
     <div class="compact-card">
       <i class="fas fa-users icon"></i>
       <div class="number">1.2M</div>
       <div class="label">Users</div>
     </div>
     <div class="compact-card">
       <i class="fas fa-dollar-sign icon"></i>
       <div class="number">\$2.4M</div>
       <div class="label">Revenue</div>
     </div>
     <div class="compact-card">
       <i class="fas fa-trophy icon"></i>
       <div class="number">#1</div>
       <div class="label">Rank</div>
     </div>
   </div>

3. PROGRESS BARS HTML:
   <div class="progress-container">
     <div class="progress-item">
       <div class="progress-label">Customer Satisfaction</div>
       <div class="progress-bar">
         <div class="progress-fill" style="width: 85%"></div>
       </div>
     </div>
     <div class="progress-item">
       <div class="progress-label">Market Share</div>
       <div class="progress-bar">
         <div class="progress-fill" style="width: 72%"></div>
       </div>
     </div>
   </div>

4. PIE CHART HTML:
   <div class="pie-chart"></div>
   <div class="chart-labels">
     <span>Category A: 40%</span>
     <span>Category B: 35%</span>
     <span>Category C: 25%</span>
   </div>

5. COMPACT BULLET POINTS HTML (for Key Insights):
   <div class="compact-bullets">
     <ul>
       <li>Key insight 1 - brief description</li>
       <li>Key insight 2 - brief description</li>
       <li>Key insight 3 - brief description</li>
     </ul>
   </div>

6. SIMPLE SUMMARY HTML (for Conclusion):
   <div class="simple-summary">
     <h3>Key Takeaways</h3>
     <ul>
       <li>Main takeaway 1</li>
       <li>Main takeaway 2</li>
       <li>Main takeaway 3</li>
     </ul>
   </div>

7. BEFORE/AFTER HTML:
   <div class="comparison-layout">
     <div class="comparison-side comparison-before">
       <h3>Before</h3>
       <div class="metric">\$500K</div>
       <div class="label">Revenue</div>
     </div>
     <div class="comparison-side comparison-after">
       <h3>After</h3>
       <div class="metric">\$1.2M</div>
       <div class="label">Revenue</div>
     </div>
   </div>

MANDATORY CONTENT STRUCTURE - CREATE 6-8 DISTINCT SECTIONS WITH PROFESSIONAL DESIGN:

1. TITLE SECTION (section-16-9):
   - Main title (large, bold) - white text on professional gradient
   - Subtitle (descriptive) - white text
   - Visual elements/icons - white colors
   - Professional gradient background

2. EXECUTIVE SUMMARY SECTION (section-16-9):
   - 4 CARD LAYOUT: Create 4 data cards with key highlights
   - Each card: icon + number + description
   - Card design: rounded corners, shadows, professional styling
   - White text on professional gradient

3. STATISTICS SECTION (section-16-9):
   - COMPACT DATA CARDS: Create 4 small data cards in 2x2 grid
   - Each card: small icon + number + short label
   - Maximum 2-3 key statistics only
   - Small text sizes for better fit
   - White text on professional gradient

4. DETAILED ANALYSIS SECTION (section-16-9):
   - PROGRESS BARS: Show data as progress bars
   - 3-4 progress bars with percentages
   - Animated progress indicators
   - White text on professional gradient

5. CHARTS/GRAPHS SECTION (section-16-9):
   - PIE CHART + BAR CHART: Mix of different chart types
   - CSS-generated pie chart with percentages
   - Horizontal bar chart for comparisons
   - Professional chart styling

6. KEY INSIGHTS SECTION (section-16-9):
   - COMPACT BULLET POINTS: Show 3-4 key insights as simple bullet points
   - Small text, clear spacing, no overlapping
   - Simple list format for better readability
   - White text on professional gradient

7. CONCLUSION SECTION (section-16-9):
   - SIMPLE SUMMARY: Show 2-3 key takeaways only
   - Small text, clear spacing, no overlapping
   - Simple bullet points format
   - White text on professional gradient

8. ADDITIONAL DATA SECTION (section-16-9):
   - BEFORE/AFTER COMPARISON: Show data comparisons
   - Side-by-side comparison layout
   - Visual indicators for improvements
   - White text on professional gradient

CRITICAL REQUIREMENTS TO PREVENT OVERLAP:
- Each section must be completely independent
- NO content should extend beyond section boundaries
- Use proper margins and padding (2-3vw minimum)
- Ensure all text fits within the 16:9 container
- Charts and graphs must be sized appropriately
- Bullet points must not overflow
- All content must be centered and properly spaced

DIVERSE DATA PRESENTATION REQUIREMENTS:

1. 4-CARD LAYOUT (Executive Summary):
   - Create 4 data cards in 2x2 grid
   - Each card: icon + large number + description
   - Use Font Awesome icons (fas fa-chart-line, fas fa-users, etc.)
   - Cards with rounded corners and subtle shadows

2. COMPARISON TABLE (Statistics):
   - Create HTML table with 2-3 columns
   - Headers: Metric, Value, Change
   - Alternating row colors for readability
   - Include percentage changes and trends

3. PROGRESS BARS (Detailed Analysis):
   - 3-4 progress bars with percentages
   - Each bar: label + percentage + visual bar
   - Use CSS gradients for progress fills
   - Animate progress bars with CSS

4. PIE CHART + BAR CHART (Charts/Graphs):
   - CSS pie chart using conic-gradient
   - Horizontal bar chart for comparisons
   - Color-coded segments with labels
   - Responsive sizing for mobile

5. TIMELINE LAYOUT (Key Insights):
   - 3-4 timeline items with connecting lines
   - Each item: date/point + description
   - Vertical timeline with dots and lines
   - Clear visual hierarchy

6. METRIC CARDS GRID (Conclusion):
   - 4 metric cards in 2x2 grid
   - Each card: large number + label + trend
   - Include trend indicators (up/down arrows)
   - Professional card design

7. BEFORE/AFTER COMPARISON (Additional Data):
   - Side-by-side comparison layout
   - Before: red theme, After: green theme
   - Visual indicators for improvements
   - Clear contrast between states

OPTIMIZED DATA AMOUNT FOR 16:9 SECTIONS:
- Maximum 3-4 data points per section
- Use compact layouts to prevent overlapping
- Small text sizes for better fit
- Clear spacing between elements
- Prioritize readability over data density

SPECIFIC SECTION REQUIREMENTS:
- Section 3 (Statistics): Maximum 4 compact cards, small text
- Section 6 (Key Insights): Maximum 3 bullet points, small text
- Section 7 (Conclusion): Maximum 3 takeaways, small text
- All sections: Ensure no overlapping, clear headings

TEXT-ONLY DESIGN REQUIREMENTS:

CSS-BASED VISUAL ELEMENTS:
- Use Font Awesome icons for visual elements (fas fa-chart-bar, fas fa-users, etc.)
- Create CSS gradients and shadows for visual depth
- Use CSS shapes and borders for decorative elements
- Implement CSS animations and transitions
- Create data visualizations using pure CSS (progress bars, charts)
- Use color schemes and typography for visual hierarchy
- Include CSS-generated patterns and geometric shapes

NO EXTERNAL IMAGES - FOCUS ON:
- Rich textual content and data
- CSS-based visual design
- Icon fonts and SVG graphics
- Color schemes and typography
- CSS animations and effects

DESIGN APPROACH FOR DIFFERENT TOPICS:

FOR CRICKET/SPORTS TOPICS (e.g., 1992 Cricket World Cup, sports stats):
- Use sports-related icons (fas fa-trophy, fas fa-medal, fas fa-users)
- Create CSS charts for statistics and data visualization
- Use color schemes that represent sports/competition
- Focus on data-rich content with statistics and facts

FOR FOOD TOPICS (e.g., biryani, Indian cuisine):
- Use food-related icons (fas fa-utensils, fas fa-fire, fas fa-leaf)
- Create CSS visualizations for ingredients and nutrition data
- Use warm color schemes that represent food/cooking
- Focus on detailed information about preparation and ingredients

FOR TECHNOLOGY TOPICS (e.g., AI, blockchain):
- Use tech-related icons (fas fa-robot, fas fa-microchip, fas fa-code)
- Create CSS charts for data analytics and trends
- Use modern, tech-inspired color schemes
- Focus on technical specifications and data points

FOR COUNTRY TOPICS (e.g., Pakistan, India):
- Use geography-related icons (fas fa-flag, fas fa-map, fas fa-building)
- Create CSS visualizations for demographic and economic data
- Use national color schemes where appropriate
- Focus on comprehensive country information and statistics

DESIGN CHECKLIST - MANDATORY:
- Does the design use appropriate icons for the topic? YES/NO
- Is the color scheme professional and relevant? YES/NO
- Are there sufficient data visualizations using CSS? YES/NO
- Is the content rich and informative? YES/NO
- Does it look professional without external images? YES/NO

Create an infographic that looks like it was designed by a professional design agency with rich data, beautiful visuals, and modern styling optimized specifically for mobile viewing that will impress users.
'''),
    );
  }
  Future<InfographicModel> generateInfographic(String prompt) async {
    await _ensureModelInitialized();
    final content = [Content.text(prompt)];
    
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final response = await _model!.generateContent(content);
        
        // Debug logging for API response
        print('🔍 DEBUG: Gemini API response received on attempt $attempt');
        print('🔍 DEBUG: Response length: ${response.text?.length ?? 0} characters');
        if (response.text != null && response.text!.isNotEmpty) {
          print('🔍 DEBUG: Response preview: ${response.text!.substring(0, response.text!.length > 200 ? 200 : response.text!.length)}...');
        }
      
      // dp.log(response.text!);
      // final response = '''
      // ```json
      //       {
      //         "html": "\"\"" ,"css": "\"\""   }
      //       ```
      // ''';
      // final response = '''
      // ```json
      //       {
      //         "html": "<div class=\"container\">\n  <header>\n    <h1 class=\"title\">Variables in C++</h1>\n    <p class=\"subtitle\">Understanding the Fundamentals</p>\n  </header>\n\n  <section class=\"overview\">\n    <h2 class=\"section-title\">What are Variables?</h2>\n    <p class=\"fact\">Variables are named storage locations that hold data values. They are the fundamental building blocks of any C++ program, enabling you to store, manipulate, and retrieve information.</p>\n    <img src=\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'%3E%3Crect x='10' y='10' width='80' height='80' fill='%234CAF50'/%3E%3Ctext x='50' y='50' dominant-baseline='middle' text-anchor='middle' fill='white' font-size='12'%3EVARIABLE%3C/text%3E%3C/svg%3E\" alt=\"Variable Icon\" class=\"icon\">\n  </section>\n\n  <section class=\"types\">\n    <h2 class=\"section-title\">Variable Types</h2>\n    <div class=\"type-grid\">\n      <div class=\"type-item\">\n        <h3 class=\"type-name\">Integer (int)</h3>\n        <p class=\"type-description\">Stores whole numbers (e.g., -10, 0, 25).</p>\n      </div>\n      <div class=\"type-item\">\n        <h3 class=\"type-name\">Floating-point (float/double)</h3>\n        <p class=\"type-description\">Stores decimal numbers (e.g., 3.14, -2.5).</p>\n      </div>\n      <div class=\"type-item\">\n        <h3 class=\"type-name\">Character (char)</h3>\n        <p class=\"type-description\">Stores a single character (e.g., 'A', 'z').</p>\n      </div>\n      <div class=\"type-item\">\n        <h3 class=\"type-name\">Boolean (bool)</h3>\n        <p class=\"type-description\">Stores a true or false value.</p>\n      </div>\n    </div>\n  </section>\n\n  <section class=\"declaration\">\n    <h2 class=\"section-title\">Declaration and Initialization</h2>\n    <p class=\"fact\">Before using a variable, you must declare it. Initialization assigns an initial value to the variable.</p>\n    <div class=\"code-example\">\n      <p class=\"code-line\"><code>int age; // Declaration</code></p>\n      <p class=\"code-line\"><code>age = 30; // Initialization</code></p>\n      <p class=\"code-line\"><code>int score = 100; // Declaration and Initialization</code></p>\n    </div>\n  </section>\n\n  <section class=\"scope\">\n    <h2 class=\"section-title\">Variable Scope</h2>\n    <p class=\"fact\">Scope determines where a variable can be accessed within your code. Local variables are accessible within the block they are defined, while global variables are accessible throughout the program.</p>\n    <div class=\"scope-illustration\">\n      <img src=\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'%3E%3Ccircle cx='50' cy='50' r='40' fill='%23f44336'/%3E%3Ctext x='50' y='50' dominant-baseline='middle' text-anchor='middle' fill='white' font-size='10'%3ELocal Scope%3C/text%3E%3C/svg%3E\" alt=\"Local Scope\" class=\"scope-icon\">\n      <img src=\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'%3E%3Ccircle cx='50' cy='50' r='40' fill='%232196F3'/%3E%3Ctext x='50' y='50' dominant-baseline='middle' text-anchor='middle' fill='white' font-size='10'%3EGlobal Scope%3C/text%3E%3C/svg%3E\" alt=\"Global Scope\" class=\"scope-icon\">\n    </div>\n  </section>\n\n  <section class=\"usage\">\n    <h2 class=\"section-title\">Usage in C++</h2>\n    <ul class=\"usage-list\">\n      <li class=\"usage-item\">Storing Data</li>\n      <li class=\"usage-item\">Performing Calculations</li>\n      <li class=\"usage-item\">Controlling Program Flow</li>\n    </ul>\n  </section>\n\n  <footer class=\"footer\">\n    <p class=\"footer-text\">© 2024 Infographic by AI</p>\n  </footer>\n</div>\n",
      //         "css": "body {\n  font-family: 'Arial', sans-serif;\n  margin: 0;\n  padding: 0;\n  background-color: #f4f4f4;\n  color: #333;\n  line-height: 1.6;\n  display: flex;\n  justify-content: center;\n  align-items: flex-start;\n  min-height: 100vh;\n}\n\n.container {\n  max-width: 400px;\n  padding: 20px;\n  background-color: #fff;\n  border-radius: 8px;\n  box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);\n  margin-top: 20px;\n}\n\nheader {\n  text-align: center;\n  margin-bottom: 20px;\n}\n\n.title {\n  font-size: 2em;\n  color: #007bff;\n  margin-bottom: 5px;\n}\n\n.subtitle {\n  font-size: 1.1em;\n  color: #6c757d;\n}\n\n.section-title {\n  font-size: 1.5em;\n  color: #333;\n  margin-bottom: 15px;\n  border-bottom: 1px solid #ccc;\n  padding-bottom: 5px;\n}\n\n.overview, .types, .declaration, .scope, .usage {\n  margin-bottom: 20px;\n  padding: 10px;\n  border-radius: 4px;\n  background-color: #f9f9f9;\n}\n\n.fact {\n  margin-bottom: 10px;\n}\n\n.icon {\n  width: 50px;\n  height: 50px;\n  display: block;\n  margin: 15px auto;\n}\n\n.type-grid {\n  display: grid;\n  grid-template-columns: 1fr;\n  gap: 15px;\n}\n\n.type-item {\n  padding: 10px;\n  border: 1px solid #ddd;\n  border-radius: 4px;\n  background-color: #fff;\n}\n\n.type-name {\n  font-weight: bold;\n  margin-bottom: 5px;\n}\n\n.type-description {\n  font-size: 0.9em;\n}\n\n.code-example {\n  background-color: #f0f0f0;\n  padding: 10px;\n  border-radius: 4px;\n}\n\n.code-line {\n  font-family: monospace;\n  font-size: 0.9em;\n}\n\n.scope-illustration {\n    display: flex;\n    justify-content: space-around;\n    margin-top: 15px;\n}\n\n.scope-icon {\n  width: 40px;\n  height: 40px;\n}\n\n.usage-list {\n  list-style: none;\n  padding: 0;\n}\n\n.usage-item {\n  padding: 8px;\n  border-bottom: 1px solid #eee;\n}\n\n.usage-item:last-child {\n  border-bottom: none;\n}\n\n.footer {\n  text-align: center;\n  margin-top: 20px;\n  padding-top: 10px;\n  border-top: 1px solid #eee;\n  font-size: 0.8em;\n  color: #666;\n}\n\n@media (max-width: 480px) {\n  .container {\n    max-width: 90%;\n  }\n\n  .type-grid {\n    grid-template-columns: 1fr;\n  }\n}\n"
      //       }
      //       ```
      // ''';
      print(response.text);
      // if (true) {
      if (response.text != null) {
        // Clean the response to extract JSON
        String cleanedResponse = response.text!.trim();

        // Remove markdown code blocks if present
        if (cleanedResponse.startsWith('```json')) {
          cleanedResponse = cleanedResponse.substring(7);
        }
        if (cleanedResponse.startsWith('```')) {
          cleanedResponse = cleanedResponse.substring(3);
        }
        if (cleanedResponse.endsWith('```')) {
          cleanedResponse = cleanedResponse.substring(
            0,
            cleanedResponse.length - 3,
          );
        }
        cleanedResponse = cleanedResponse.trim();
        
        // Fix common JSON issues: unescaped quotes and control characters
        cleanedResponse = _fixJsonString(cleanedResponse);
        
        // dp.log(cleanedResponse);

        try {
          // Debug logging for JSON parsing
          print('🔍 DEBUG: Attempting to parse JSON response');
          print('🔍 DEBUG: Cleaned response length: ${cleanedResponse.length}');
          print('🔍 DEBUG: Cleaned response preview: ${cleanedResponse.substring(0, cleanedResponse.length > 300 ? 300 : cleanedResponse.length)}...');
          
          // Validate JSON structure before parsing
          if (!_isValidJsonStructure(cleanedResponse)) {
            throw FormatException('Invalid JSON structure detected');
          }
          
          final jsonData = jsonDecode(cleanedResponse);
          
          // Debug logging for parsed JSON
          print('🔍 DEBUG: JSON parsed successfully');
          print('🔍 DEBUG: JSON keys: ${jsonData.keys.toList()}');
          if (jsonData.containsKey('html')) {
            print('🔍 DEBUG: HTML length: ${jsonData['html'].toString().length}');
            print('🔍 DEBUG: HTML preview: ${jsonData['html'].toString().substring(0, jsonData['html'].toString().length > 200 ? 200 : jsonData['html'].toString().length)}...');
          }
          if (jsonData.containsKey('css')) {
            print('🔍 DEBUG: CSS length: ${jsonData['css'].toString().length}');
          }
          
          // Debug logging for image analysis
          if (jsonData.containsKey('html')) {
            final htmlContent = jsonData['html'].toString();
            print('🔍 DEBUG: Analyzing images in HTML content...');
            
            // Count image tags
            final imageTags = RegExp(r'<img[^>]*>').allMatches(htmlContent).toList();
            print('🔍 DEBUG: Found ${imageTags.length} image tags in HTML');
            
            // Extract image sources
            final imageSources = <String>[];
            final srcRegex = RegExp(r'src="([^"]*)"');
            for (final match in imageTags) {
              final imgTag = match.group(0)!;
              final srcMatch = srcRegex.firstMatch(imgTag);
              if (srcMatch != null) {
                imageSources.add(srcMatch.group(1)!);
              }
            }
            
            print('🔍 DEBUG: Image sources found:');
            for (int i = 0; i < imageSources.length; i++) {
              print('🔍 DEBUG: Image ${i + 1}: ${imageSources[i]}');
            }
            
            // Check for duplicate images
            final uniqueImages = imageSources.toSet();
            if (uniqueImages.length != imageSources.length) {
              print('🔍 DEBUG: WARNING - Duplicate images detected!');
              print('🔍 DEBUG: Total images: ${imageSources.length}, Unique images: ${uniqueImages.length}');
              final duplicates = imageSources.where((img) => imageSources.indexOf(img) != imageSources.lastIndexOf(img)).toSet();
              print('🔍 DEBUG: Duplicate image URLs: $duplicates');
            } else {
              print('🔍 DEBUG: All images are unique - no duplicates found');
            }
            
            // Check for cricket relevance
            final cricketKeywords = ['cricket', 'stadium', 'players', 'bat', 'ball', 'wicket', 'world cup'];
            final cricketRelevantImages = imageSources.where((img) => 
              cricketKeywords.any((keyword) => img.toLowerCase().contains(keyword))
            ).toList();
            print('🔍 DEBUG: Cricket-relevant images: ${cricketRelevantImages.length}/${imageSources.length}');
            if (cricketRelevantImages.isNotEmpty) {
              print('🔍 DEBUG: Cricket-relevant image URLs: $cricketRelevantImages');
            }
            
            // Check image sources diversity
            final unsplashImages = imageSources.where((img) => img.contains('unsplash.com')).toList();
            final pexelsImages = imageSources.where((img) => img.contains('pexels.com')).toList();
            final pixabayImages = imageSources.where((img) => img.contains('pixabay.com')).toList();
            final wikimediaImages = imageSources.where((img) => img.contains('wikimedia.org')).toList();
            final googleImages = imageSources.where((img) => img.contains('google.com') || img.contains('googleusercontent.com')).toList();
            
            print('🔍 DEBUG: Image source diversity:');
            print('🔍 DEBUG: Unsplash: ${unsplashImages.length}');
            print('🔍 DEBUG: Pexels: ${pexelsImages.length}');
            print('🔍 DEBUG: Pixabay: ${pixabayImages.length}');
            print('🔍 DEBUG: Wikimedia: ${wikimediaImages.length}');
            print('🔍 DEBUG: Google: ${googleImages.length}');
            
            // Check if AI used the provided Unsplash images
            final providedUnsplashImages = unsplashImages.where((img) => 
              img.contains('images.unsplash.com/photo-')
            ).toList();
            print('🔍 DEBUG: Used provided Unsplash images: ${providedUnsplashImages.length}/${unsplashImages.length}');
            
            final totalSources = [unsplashImages, pexelsImages, pixabayImages, wikimediaImages, googleImages]
                .where((source) => source.isNotEmpty).length;
            print('🔍 DEBUG: Total image sources used: $totalSources/5');
            
            // Check data density (text content, statistics, charts)
            final textContent = htmlContent.toLowerCase();
            final statisticsCount = RegExp(r'\d+%|\d+\.\d+%|\d+\/\d+|\d+:\d+').allMatches(textContent).length;
            final chartElements = RegExp(r'chart|graph|progress|bar|pie|line').allMatches(textContent).length;
            final dataPoints = RegExp(r'statistic|data|metric|percentage|rate|growth').allMatches(textContent).length;
            
            print('🔍 DEBUG: Data density analysis:');
            print('🔍 DEBUG: Statistics found: $statisticsCount');
            print('🔍 DEBUG: Chart elements: $chartElements');
            print('🔍 DEBUG: Data points: $dataPoints');
            print('🔍 DEBUG: Total images used: ${imageSources.length}');
            
            if (imageSources.length <= 3 && statisticsCount >= 20) {
              print('🔍 DEBUG: Excellent - Minimal images with high data density!');
            } else if (imageSources.length <= 5 && statisticsCount >= 15) {
              print('🔍 DEBUG: Good - Balanced images and data content');
            } else if (imageSources.length > 5) {
              print('🔍 DEBUG: WARNING - Too many images, focus on data density!');
            } else {
              print('🔍 DEBUG: INFO - Current image and data balance');
            }
          }
          // final jsonData = json.decode(cleanedResponse);
          // return InfographicModel(
          //   htmlCode: (jsonData['html'] as List).first ?? '',
          //   cssCode: (jsonData['css'] as List).first ?? '',
          //   prompt: prompt,
          // );
          // Debug logging for final result
          print('🔍 DEBUG: Creating InfographicModel with parsed data');
          final finalHtml = (jsonData['html'] is List)
              ? (jsonData['html'] as List).join("\n")
              : (jsonData['html'] ?? '');
          final finalCss = (jsonData['css'] is List)
              ? (jsonData['css'] as List).join("\n")
              : (jsonData['css'] ?? '');
          
          print('🔍 DEBUG: Final HTML length: ${finalHtml.length}');
          print('🔍 DEBUG: Final CSS length: ${finalCss.length}');
          print('🔍 DEBUG: Infographic generation completed successfully');
          
        return InfographicModel(
          htmlCode: finalHtml,
          cssCode: finalCss,
          prompt: prompt,
        );
        } catch (e) {
          print('Error parsing JSON on attempt $attempt: $e');
          if (attempt == 3) rethrow;
        }
      } 
      } catch (e) {
        print('Error generating content on attempt $attempt: $e');
        if (attempt == 3) rethrow;
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    throw Exception('Failed to generate infographic');
  }

  /// Fixes common JSON string issues like unescaped quotes and control characters
  String _fixJsonString(String jsonString) {
    try {
      final fixed = StringBuffer();
      bool inString = false;
      bool escaped = false;
      
      for (int i = 0; i < jsonString.length; i++) {
        final char = jsonString[i];
        
        if (escaped) {
          fixed.write(char);
          escaped = false;
          continue;
        }
        
        if (char == '\\') {
          escaped = true;
          fixed.write(char);
          continue;
        }
        
        if (char == '"') {
          if (!inString) {
            // Starting a string value
            inString = true;
            fixed.write(char);
          } else {
            // Inside a string - check if this should end the string
            // Look ahead to find the next meaningful character
            bool shouldEnd = false;
            for (int j = i + 1; j < jsonString.length && j < i + 10; j++) {
              final nextChar = jsonString[j];
              if (nextChar == ':') {
                // This was a key, not a value - end the string
                shouldEnd = true;
                break;
              } else if (nextChar == ',' || nextChar == '}' || nextChar == ']') {
                // End of value - end the string
                shouldEnd = true;
                break;
              } else if (!nextChar.trim().isEmpty && nextChar != ' ') {
                // Non-whitespace character found - this quote should be escaped
                break;
              }
            }
            
            // Check if we're at the end of the string or next char suggests end
            if (i + 1 >= jsonString.length) {
              shouldEnd = true;
            } else {
              final nextNonWhitespace = jsonString.substring(i + 1).split('').firstWhere(
                (c) => c.trim().isNotEmpty,
                orElse: () => '',
              );
              if (nextNonWhitespace.isEmpty || 
                  nextNonWhitespace == ',' || 
                  nextNonWhitespace == '}' || 
                  nextNonWhitespace == ']' ||
                  nextNonWhitespace == ':') {
                shouldEnd = true;
              }
            }
            
            if (shouldEnd) {
              inString = false;
              fixed.write(char);
            } else {
              // This quote is inside the string value and should be escaped
              fixed.write('\\"');
            }
          }
        } else {
          // Replace control characters that break JSON (except newlines, tabs, carriage returns)
          if (char.codeUnitAt(0) < 32 && char != '\n' && char != '\r' && char != '\t') {
            // Skip control characters
            continue;
          }
          fixed.write(char);
        }
      }
      
      return fixed.toString();
    } catch (e) {
      print('⚠️ Warning: Error fixing JSON string: $e');
      return jsonString; // Return original if fixing fails
    }
  }

  /// Validates that the JSON string has a basic valid structure
  bool _isValidJsonStructure(String jsonString) {
    try {
      // Check for balanced braces and brackets
      int braces = 0;
      int brackets = 0;
      bool inString = false;
      bool escaped = false;
      
      for (int i = 0; i < jsonString.length; i++) {
        final char = jsonString[i];
        
        if (escaped) {
          escaped = false;
          continue;
        }
        
        if (char == '\\') {
          escaped = true;
          continue;
        }
        
        if (char == '"') {
          inString = !inString;
          continue;
        }
        
        if (inString) continue;
        
        if (char == '{') braces++;
        if (char == '}') braces--;
        if (char == '[') brackets++;
        if (char == ']') brackets--;
        
        if (braces < 0 || brackets < 0) {
          print('⚠️ Invalid JSON: Unbalanced braces/brackets');
          return false;
        }
      }
      
      if (braces != 0 || brackets != 0) {
        print('⚠️ Invalid JSON: Unbalanced braces ($braces) or brackets ($brackets)');
        return false;
      }
      
      // Check for required fields
      if (!jsonString.contains('"html"') || !jsonString.contains('"css"')) {
        print('⚠️ Invalid JSON: Missing required fields (html or css)');
        return false;
      }
      
      return true;
    } catch (e) {
      print('⚠️ Error validating JSON structure: $e');
      return false;
    }
  }
}
