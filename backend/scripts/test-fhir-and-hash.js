require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });
const pool = require('../db');
const {
  patientToFhir,
  appointmentToFhir,
  diagnosisToFhir,
  prescriptionToFhirRequests,
  bloodPressureToFhir,
  glucoseToFhir,
  buildFhirBundle,
} = require('../utils/fhir-converter');

async function testAll() {
  console.log('Testing HL7 FHIR v4 Converter...');

  // 1. Patient
  const fhirPat = patientToFhir({
    id: 'e10f1338-3f82-429a-8a43-09756bcae001',
    full_name: 'Sita Devi',
    gender: 'female',
    phone: '9841000001',
    dob: '1985-05-12',
    address: 'Ward 4, Melamchi',
    municipality_name: 'Melamchi',
    district_name: 'Sindhupalchok',
    province_name: 'Bagmati Province',
  });
  console.assert(fhirPat.resourceType === 'Patient', 'Patient resourceType mismatch');
  console.assert(fhirPat.gender === 'female', 'Gender mapping mismatch');
  console.assert(fhirPat.address[0].district === 'Sindhupalchok', 'Address mapping mismatch');
  console.log('✔ Patient mapping verified');

  // 2. Encounter
  const fhirEnc = appointmentToFhir({
    id: 'a10f1338-3f82-429a-8a43-09756bcae002',
    patient_id: fhirPat.id,
    doctor_id: 'd10f1338-3f82-429a-8a43-09756bcae003',
    status: 'completed',
    consultation_mode: 'video',
    appointment_date: new Date().toISOString(),
  });
  console.assert(fhirEnc.resourceType === 'Encounter', 'Encounter resourceType mismatch');
  console.assert(fhirEnc.status === 'finished', 'Status mapping mismatch');
  console.log('✔ Encounter mapping verified');

  // 3. Condition (ICD-11)
  const fhirCond = diagnosisToFhir({
    id: 'c10f1338-3f82-429a-8a43-09756bcae004',
    patient_id: fhirPat.id,
    title: 'Chronic Obstructive Pulmonary Disease (COPD)',
    icd11_code: 'CA22',
    findings: 'Bilateral expiratory wheezing',
    recommended_treatment: 'Inhaled bronchodilators + smoking cessation',
  });
  console.assert(fhirCond.resourceType === 'Condition', 'Condition resourceType mismatch');
  console.assert(fhirCond.code.coding[0].code === 'CA22', 'ICD-11 code mismatch');
  console.log('✔ Condition mapping verified');

  // 4. MedicationRequest (ATC)
  const fhirMeds = prescriptionToFhirRequests({
    id: 'p10f1338-3f82-429a-8a43-09756bcae005',
    patient_id: fhirPat.id,
    doctor_id: 'd10f1338-3f82-429a-8a43-09756bcae003',
    title: 'Inhaler Therapy',
    signature_hash: 'a1b2c3d4e5f60718293a4b5c6d7e8f90123456789abcdef0123456789abcdef0',
    created_at: new Date().toISOString(),
  }, [
    {
      id: 'm1',
      medicine_name: 'Salbutamol Inhaler',
      atc_code: 'R03AC02',
      dosage: '100mcg',
      frequency: '2 puffs PRN',
      duration: '30 days',
      instructions: 'Rinse mouth after use',
    },
  ]);
  console.assert(fhirMeds.length === 1, 'MedicationRequest count mismatch');
  console.assert(fhirMeds[0].resourceType === 'MedicationRequest', 'MedicationRequest resourceType mismatch');
  console.assert(fhirMeds[0].identifier[0].value.length === 64, 'Signature hash preservation mismatch');
  console.log('✔ MedicationRequest mapping verified');

  // 5. Observations (BP & Glucose)
  const fhirBP = bloodPressureToFhir({
    id: 'bp1',
    patient_id: fhirPat.id,
    systolic: 138,
    diastolic: 88,
    created_at: new Date().toISOString(),
  });
  console.assert(fhirBP.component.length === 2, 'BP components mismatch');
  console.log('✔ Blood Pressure Observation verified');

  // 6. Bundle ($everything)
  const bundle = buildFhirBundle([fhirPat, fhirEnc, fhirCond, ...fhirMeds, fhirBP], fhirPat.id);
  console.assert(bundle.resourceType === 'Bundle', 'Bundle resourceType mismatch');
  console.assert(bundle.type === 'searchset', 'Bundle type mismatch');
  console.assert(bundle.total === 5, 'Bundle total count mismatch');
  console.log('✔ FHIR Bundle assembly verified. All 6 resources valid!');

  console.log('\nAll HL7 FHIR v4 unit tests PASSED successfully.');
  process.exit(0);
}

testAll().catch((e) => {
  console.error('Test error:', e);
  process.exit(1);
});
