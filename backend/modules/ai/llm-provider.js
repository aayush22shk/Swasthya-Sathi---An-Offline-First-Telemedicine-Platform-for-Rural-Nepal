const { GoogleGenerativeAI, SchemaType } = require('@google/generative-ai');

const PROMPT_VERSION = '1.0.0';
const MODEL_CANDIDATES = ['gemini-3.6-flash', 'gemini-3.5-flash', 'gemini-3.8-flash', 'gemini-3.7-flash'];
const MODEL_NAME = MODEL_CANDIDATES[0];

// ─── RESPONSE SCHEMA ─────────────────────────────────────────────────────────
// Enforces structured output from the LLM — never trust free-form health text.
const AI_EXPLANATION_SCHEMA = {
  type: SchemaType.OBJECT,
  properties: {
    summary: {
      type: SchemaType.STRING,
      description: 'A plain-language 2-4 sentence summary of the patient\'s health status.',
      nullable: false,
    },
    observations: {
      type: SchemaType.ARRAY,
      items: {
        type: SchemaType.OBJECT,
        properties: {
          category: { type: SchemaType.STRING },
          message: { type: SchemaType.STRING },
          severity: { type: SchemaType.STRING, enum: ['info', 'warning', 'alert'] },
        },
        required: ['category', 'message', 'severity'],
      },
    },
    recommendations: {
      type: SchemaType.ARRAY,
      items: {
        type: SchemaType.OBJECT,
        properties: {
          type: { type: SchemaType.STRING },
          message: { type: SchemaType.STRING },
        },
        required: ['type', 'message'],
      },
    },
    questions_for_clinician: {
      type: SchemaType.ARRAY,
      items: { type: SchemaType.STRING },
    },
    safety_message: {
      type: SchemaType.STRING,
      nullable: true,
      description: 'Only populated if there is an urgent concern requiring immediate medical attention.',
    },
    disclaimer: {
      type: SchemaType.STRING,
      nullable: true,
    },
  },
  required: ['summary', 'observations', 'recommendations'],
};

// ─── SYSTEM PROMPT ────────────────────────────────────────────────────────────
const buildSystemPrompt = (language = 'en') => {
  const langLabel = language === 'ne' ? 'Nepali (नेपाली)' : 'English';
  return `You are a health-education assistant for SwasthyaSathi, a telemedicine platform serving rural Nepal.

RULES (MANDATORY):
- You receive pre-computed, validated health statistics. You must NEVER recalculate statistics from raw numbers.
- You must NEVER diagnose, prescribe, or change medications.
- You must NEVER override the clinical flags already identified by the system.
- You must NEVER invent thresholds or reference values not grounded in standard clinical guidelines.
- You must NEVER use patient names, phone numbers, or other direct identifiers.
- If any flag has severity "critical", the safety_message field MUST be populated with a clear urgent action message.
- Your role is to explain the pre-computed analysis in plain, accessible language.
- Respond in ${langLabel}. Keep language simple and avoid medical jargon where possible.
- Always include a disclaimer noting that this is educational information and not a substitute for medical advice.

WHAT YOU WILL RECEIVE:
A JSON object containing:
- patient_context: age range, sex, active conditions, active medications
- period: the analysis time window (e.g., "Last 30 days")
- blood_pressure: pre-computed statistics (averages, trend, measurement count)
- glucose: pre-computed statistics
- weight: pre-computed statistics
- flags: list of clinical rule flags already applied by the system

YOUR TASK:
Generate a JSON response matching the required schema with:
1. summary: 2-4 sentences explaining the health picture in plain language
2. observations: one observation per flag/category (max 6 total)
3. recommendations: 2-4 practical, actionable health tips
4. questions_for_clinician: 2-3 questions the patient might want to ask their doctor
5. safety_message: only if a critical flag exists; otherwise null
6. disclaimer: standard medical disclaimer`;
};

// ─── CONTEXT BUILDER ──────────────────────────────────────────────────────────
// Build compact, anonymized context — never send full patient records to LLM
const buildContext = (analysisResult, patientInfo, language) => {
  const { result, period_start, period_end, conditions, medications } = analysisResult;

  const start = new Date(period_start);
  const end = new Date(period_end);
  const diffDays = Math.round((end - start) / (1000 * 60 * 60 * 24));

  return {
    patient_context: {
      age_range: patientInfo?.age_range || 'unknown',
      sex: patientInfo?.gender || 'unknown',
      active_conditions: (conditions || []).map(c => c.condition_name),
      active_medications: (medications || []).map(m => m.medicine_name),
    },
    period: `Last ${diffDays} days`,
    blood_pressure: result?.blood_pressure || null,
    glucose: result?.glucose || null,
    weight: result?.weight || null,
    flags: result?.flags || [],
  };
};

// ─── OUTPUT VALIDATOR ─────────────────────────────────────────────────────────
const validateLLMOutput = (output) => {
  if (!output || typeof output !== 'object') throw new Error('LLM returned invalid response structure.');
  if (!output.summary || typeof output.summary !== 'string') throw new Error('LLM response missing summary.');
  if (!Array.isArray(output.observations)) output.observations = [];
  if (!Array.isArray(output.recommendations)) output.recommendations = [];
  if (!Array.isArray(output.questions_for_clinician)) output.questions_for_clinician = [];
  // Safety: if any critical flag exists, ensure safety_message is set
  if (!output.safety_message) output.safety_message = null;
  return output;
};

// ─── MAIN EXPLANATION FUNCTION ───────────────────────────────────────────────

const generateHealthExplanation = async (analysisResult, patientInfo, language = 'en') => {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    console.warn('[LLMProvider] GEMINI_API_KEY not set — returning placeholder explanation.');
    return {
      summary: 'AI explanation is not available at this time. Please review your health data with your doctor.',
      observations: (analysisResult.result?.flags || []).map(f => ({
        category: f.category,
        message: f.message,
        severity: f.severity,
      })),
      recommendations: [
        { type: 'monitoring', message: 'Continue recording your vitals regularly.' },
        { type: 'consultation', message: 'Discuss your health trends with your doctor at your next appointment.' },
      ],
      questions_for_clinician: ['Are my current readings within a healthy range for me?'],
      safety_message: null,
      disclaimer: 'This is educational information and not a substitute for professional medical advice.',
      _source: 'fallback',
    };
  }

  const genAI = new GoogleGenerativeAI(apiKey);
  const context = buildContext(analysisResult, patientInfo, language);
  const systemPrompt = buildSystemPrompt(language);

  let lastError = null;
  for (const modelCandidate of MODEL_CANDIDATES) {
    try {
      const model = genAI.getGenerativeModel({
        model: modelCandidate,
        generationConfig: {
          responseMimeType: 'application/json',
          responseSchema: AI_EXPLANATION_SCHEMA,
        },
      });

      const result = await model.generateContent([systemPrompt, JSON.stringify(context)]);
      const rawText = result.response.text();
      const parsed = JSON.parse(rawText);
      const validated = validateLLMOutput(parsed);

      return { ...validated, _source: modelCandidate, _prompt_version: PROMPT_VERSION };
    } catch (err) {
      console.warn(`[LLMProvider] Model ${modelCandidate} failed (${err.message?.split('\n')[0]}), trying next candidate...`);
      lastError = err;
    }
  }

  throw lastError || new Error('All Gemini model candidates failed.');
};

// ─── CHAT FUNCTION ────────────────────────────────────────────────────────────
const generateChatResponse = async (conversationHistory, latestAnalysis, language = 'en') => {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    return { role: 'assistant', content: 'AI chat is not available at this time. Please consult your doctor for medical questions.' };
  }

  const genAI = new GoogleGenerativeAI(apiKey);
  const chatSystemPrompt = `${buildSystemPrompt(language)}

ADDITIONAL CHAT RULES:
- You are in a conversational context. Answer the patient's question using the health data context provided.
- Keep answers concise (2-4 sentences).
- Always remind the patient to consult their doctor for medical decisions.
- You have access to the patient's last health analysis as context.

PATIENT'S LATEST HEALTH SUMMARY:
${latestAnalysis ? JSON.stringify(latestAnalysis.result?.blood_pressure) : 'No recent analysis available.'}`;

  let lastError = null;
  for (const modelCandidate of MODEL_CANDIDATES) {
    try {
      const model = genAI.getGenerativeModel({ model: modelCandidate });
      const chat = model.startChat({
        history: conversationHistory.slice(0, -1).map(msg => ({
          role: msg.role === 'user' ? 'user' : 'model',
          parts: [{ text: msg.content }],
        })),
        systemInstruction: chatSystemPrompt,
      });

      const lastMessage = conversationHistory[conversationHistory.length - 1];
      const result = await chat.sendMessage(lastMessage.content);
      return { role: 'assistant', content: result.response.text(), _source: modelCandidate };
    } catch (err) {
      console.warn(`[LLMProvider] Chat model ${modelCandidate} failed, trying next candidate...`);
      lastError = err;
    }
  }

  throw lastError || new Error('All Gemini chat model candidates failed.');
};

module.exports = { generateHealthExplanation, generateChatResponse, PROMPT_VERSION, MODEL_NAME };
