require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });
const pool = require('../db');
const skinService = require('../modules/skin-analysis/skin-analysis.service');

async function testSkinAnalysisModule() {
  console.log('Testing Skin Analysis Backend Service & DB...');

  // 1. Get a test patient and test doctor
  const patRes = await pool.query('SELECT p.id, p.user_id, p.full_name FROM patients p LIMIT 1');
  if (!patRes.rows.length) throw new Error('No patients in database to test.');
  const testPatient = patRes.rows[0];

  const docRes = await pool.query('SELECT d.id, d.user_id, d.full_name FROM doctors d LIMIT 1');
  if (!docRes.rows.length) throw new Error('No doctors in database to test.');
  const testDoctor = docRes.rows[0];

  console.log(`Using Patient: ${testPatient.full_name} (${testPatient.id})`);
  console.log(`Using Doctor:  ${testDoctor.full_name} (${testDoctor.id})`);

  // 2. Create skin analysis record
  const created = await skinService.createSkinAnalysis(testPatient.user_id, {
    image_url: 'file:///data/user/0/np.gov.swasthyasathi/files/skin_tinea_test.jpg',
    predicted_condition: 'Tinea / Ringworm (Fungal)',
    confidence_score: 0.8924,
    top_predictions: [
      { class_key: 'tinea_ringworm', condition_name: 'Tinea / Ringworm (Fungal)', confidence: 0.8924 },
      { class_key: 'eczema', condition_name: 'Eczema (Atopic / Contact Dermatitis)', confidence: 0.0612 },
      { class_key: 'psoriasis', condition_name: 'Psoriasis (Plaque)', confidence: 0.0245 },
    ],
    is_uncertain: false,
    model_version: 'mobilenetv3_nepal_v1',
  });

  console.assert(created.id, 'Created analysis missing id');
  console.assert(Number(created.confidence_score) === 0.8924, 'Confidence score mismatch');
  console.log('✔ Skin analysis created successfully:', created.id);

  // 3. List patient analyses
  const list = await skinService.getPatientAnalyses(testPatient.user_id);
  console.assert(list.length > 0, 'Analyses list empty');
  console.assert(list.some(x => x.id === created.id), 'Created analysis not in list');
  console.log(`✔ Patient analyses list verified (${list.length} records)`);

  // 4. Share with doctor
  const shared = await skinService.shareAnalysisWithDoctor(created.id, testPatient.user_id, {
    doctor_id: testDoctor.id,
  });
  console.assert(shared.is_shared_with_doctor === true, 'Sharing flag not set');
  console.assert(shared.doctor_id === testDoctor.id, 'Doctor ID mismatch');
  console.log('✔ Analysis shared with doctor verified');

  // 5. Doctor review
  const reviewed = await skinService.reviewSkinAnalysis(created.id, testDoctor.user_id, {
    doctor_notes: 'Typical annular active border compatible with Tinea corporis. Recommended topical terbinafine cream 1% BID x 2 weeks.',
  });
  console.assert(reviewed.doctor_notes.includes('terbinafine'), 'Doctor notes mismatch');
  console.assert(reviewed.reviewed_at !== null, 'Reviewed timestamp missing');
  console.log('✔ Doctor clinical review recorded verified');

  // 6. Audit Trail Check
  const auditRes = await pool.query(
    `SELECT * FROM audit_logs WHERE entity_type = 'skin_analyses' AND entity_id = $1 ORDER BY created_at DESC`,
    [created.id]
  );
  console.assert(auditRes.rows.length >= 2, 'Audit logs missing entries');
  console.log(`✔ Audit trail verified (${auditRes.rows.length} log events recorded)`);

  console.log('\nAll Skin Analysis Backend Tests PASSED successfully!');
  await pool.end();
  process.exit(0);
}

testSkinAnalysisModule().catch(err => {
  console.error('Test error:', err);
  process.exit(1);
});
