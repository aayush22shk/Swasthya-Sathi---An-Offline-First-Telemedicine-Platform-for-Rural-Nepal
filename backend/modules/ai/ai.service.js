const pool = require('../../db');
const { generateHealthExplanation, generateChatResponse, PROMPT_VERSION, MODEL_NAME } = require('./llm-provider');

// ─── AI EXPLAIN ──────────────────────────────────────────────────────────────

const getPatientContext = async (patient_id) => {
  const res = await pool.query(
    `SELECT gender, dob FROM patients WHERE id = $1`,
    [patient_id]
  );
  if (res.rows.length === 0) return {};
  const p = res.rows[0];
  const age = p.dob ? Math.floor((Date.now() - new Date(p.dob)) / (365.25 * 24 * 3600 * 1000)) : null;
  return {
    gender: p.gender,
    age_range: age ? (age < 18 ? '<18' : age < 40 ? '18-39' : age < 60 ? '40-59' : '60+') : 'unknown',
  };
};

const explainAnalysis = async (patient_id, analysis_id, language = 'en') => {
  // 1. Load analysis
  let analysisRes;
  if (analysis_id) {
    analysisRes = await pool.query('SELECT * FROM health_analyses WHERE id = $1 AND patient_id = $2', [analysis_id, patient_id]);
  } else {
    analysisRes = await pool.query('SELECT * FROM health_analyses WHERE patient_id = $1 ORDER BY generated_at DESC LIMIT 1', [patient_id]);
  }
  if (analysisRes.rows.length === 0) {
    const err = new Error('No health analysis found to explain. Please generate an analysis first.');
    err.statusCode = 404; throw err;
  }
  const analysis = analysisRes.rows[0];

  // 2. Load conditions and medications for context
  const [condRes, medRes] = await Promise.all([
    pool.query('SELECT condition_name FROM patient_conditions WHERE patient_id = $1 AND status = \'active\'', [patient_id]),
    pool.query('SELECT medicine_name FROM patient_medications WHERE patient_id = $1 AND is_active = true', [patient_id]),
  ]);
  const fullAnalysis = { ...analysis, conditions: condRes.rows, medications: medRes.rows };

  // 3. Get patient context (anonymized)
  const patientInfo = await getPatientContext(patient_id);

  // 4. Generate LLM explanation
  const explanation = await generateHealthExplanation(fullAnalysis, patientInfo, language);

  // 5. Persist AI feedback for auditability
  await pool.query(
    `INSERT INTO ai_health_feedback (patient_id, analysis_id, model_provider, model_name, prompt_version, context, response)
     VALUES ($1, $2, 'google', $3, $4, $5::jsonb, $6::jsonb)`,
    [patient_id, analysis.id, MODEL_NAME, PROMPT_VERSION,
     JSON.stringify({ period: analysis.period_start + ' to ' + analysis.period_end }),
     JSON.stringify(explanation)]
  );

  return { analysis_id: analysis.id, generated_at: new Date().toISOString(), language, ...explanation };
};

// ─── AI CONVERSATIONS ─────────────────────────────────────────────────────────

const startConversation = async (patient_id, title) => {
  const res = await pool.query(
    `INSERT INTO ai_conversations (patient_id, title) VALUES ($1, $2) RETURNING *`,
    [patient_id, title || 'Health Chat']
  );
  return res.rows[0];
};

const getConversations = async (patient_id) => {
  const res = await pool.query(
    `SELECT * FROM ai_conversations WHERE patient_id = $1 ORDER BY updated_at DESC LIMIT 20`,
    [patient_id]
  );
  return res.rows;
};

const getConversationMessages = async (conversation_id, patient_id) => {
  // Verify ownership
  const convRes = await pool.query(
    'SELECT id FROM ai_conversations WHERE id = $1 AND patient_id = $2', [conversation_id, patient_id]
  );
  if (convRes.rows.length === 0) {
    const err = new Error('Conversation not found.'); err.statusCode = 404; throw err;
  }
  const res = await pool.query(
    `SELECT id, role, content, created_at FROM ai_messages WHERE conversation_id = $1 ORDER BY created_at ASC`,
    [conversation_id]
  );
  return res.rows;
};

const sendChatMessage = async (patient_id, conversation_id, userMessage, language = 'en') => {
  // Verify ownership
  const convRes = await pool.query(
    'SELECT id FROM ai_conversations WHERE id = $1 AND patient_id = $2', [conversation_id, patient_id]
  );
  if (convRes.rows.length === 0) {
    const err = new Error('Conversation not found.'); err.statusCode = 404; throw err;
  }

  // Save user message
  await pool.query(
    `INSERT INTO ai_messages (conversation_id, role, content) VALUES ($1, 'user', $2)`,
    [conversation_id, userMessage]
  );

  // Load history (last 10 messages for context)
  const histRes = await pool.query(
    `SELECT role, content FROM ai_messages WHERE conversation_id = $1 ORDER BY created_at DESC LIMIT 10`,
    [conversation_id]
  );
  const history = histRes.rows.reverse();

  // Load latest analysis for context
  const latestAnalysis = await pool.query(
    `SELECT result FROM health_analyses WHERE patient_id = $1 ORDER BY generated_at DESC LIMIT 1`,
    [patient_id]
  );

  // Generate AI response
  const aiResponse = await generateChatResponse(
    [...history, { role: 'user', content: userMessage }],
    latestAnalysis.rows[0] || null,
    language
  );

  // Save AI response
  const savedResponse = await pool.query(
    `INSERT INTO ai_messages (conversation_id, role, content) VALUES ($1, 'assistant', $2) RETURNING *`,
    [conversation_id, aiResponse.content]
  );

  // Update conversation timestamp
  await pool.query(`UPDATE ai_conversations SET updated_at = now() WHERE id = $1`, [conversation_id]);

  return savedResponse.rows[0];
};

module.exports = { explainAnalysis, startConversation, getConversations, getConversationMessages, sendChatMessage };
