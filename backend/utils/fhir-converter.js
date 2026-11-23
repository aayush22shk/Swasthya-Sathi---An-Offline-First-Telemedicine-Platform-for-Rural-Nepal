/**
 * HL7 FHIR v4 Converter for Swasthya Sathi
 * Maps internal PostgreSQL schema entities to standard HL7 FHIR Release 4 resources.
 */

/**
 * Converts a patient record to FHIR Patient resource.
 */
function patientToFhir(patient) {
  if (!patient) return null;

  const fhirPatient = {
    resourceType: 'Patient',
    id: String(patient.id),
    identifier: [
      {
        use: 'official',
        system: 'https://swasthyasathi.gov.np/patients',
        value: String(patient.id),
      },
    ],
    active: true,
    name: [
      {
        use: 'official',
        text: patient.full_name || 'Anonymous Patient',
      },
    ],
    gender: mapGender(patient.gender),
    birthDate: patient.dob ? new Date(patient.dob).toISOString().split('T')[0] : undefined,
    telecom: [],
    address: [],
  };

  if (patient.phone) {
    fhirPatient.telecom.push({
      system: 'phone',
      value: patient.phone,
      use: 'mobile',
    });
  }
  if (patient.email) {
    fhirPatient.telecom.push({
      system: 'email',
      value: patient.email,
    });
  }

  if (patient.address || patient.municipality_name || patient.district_name || patient.province_name) {
    fhirPatient.address.push({
      use: 'home',
      line: patient.address ? [patient.address] : [],
      city: patient.municipality_name || undefined,
      district: patient.district_name || undefined,
      state: patient.province_name || undefined,
      country: 'Nepal',
    });
  }

  return fhirPatient;
}

function mapGender(gender) {
  if (!gender) return 'unknown';
  const g = String(gender).toLowerCase();
  if (g === 'male' || g === 'm') return 'male';
  if (g === 'female' || g === 'f') return 'female';
  return 'other';
}

/**
 * Converts an appointment or consultation into a FHIR Encounter resource.
 */
function appointmentToFhir(appt) {
  if (!appt) return null;

  const statusMap = {
    completed: 'finished',
    confirmed: 'arrived',
    pending: 'planned',
    cancelled: 'cancelled',
    no_show: 'noshow',
  };

  return {
    resourceType: 'Encounter',
    id: String(appt.id),
    status: statusMap[appt.status] || 'unknown',
    class: {
      system: 'http://terminology.hl7.org/CodeSystem/v3-ActCode',
      code: appt.consultation_mode === 'in_person' ? 'AMB' : 'VR',
      display: appt.consultation_mode === 'in_person' ? 'ambulatory' : 'virtual',
    },
    subject: {
      reference: `Patient/${appt.patient_id}`,
      display: appt.patient_name || undefined,
    },
    participant: appt.doctor_id ? [
      {
        individual: {
          reference: `Practitioner/${appt.doctor_id}`,
          display: appt.doctor_name || undefined,
        },
      },
    ] : [],
    period: {
      start: appt.appointment_date ? new Date(appt.appointment_date).toISOString() : undefined,
      end: appt.appointment_date ? new Date(appt.appointment_date).toISOString() : undefined,
    },
  };
}

/**
 * Converts a diagnosis_result or patient_condition into a FHIR Condition resource.
 */
function diagnosisToFhir(dx) {
  if (!dx) return null;

  return {
    resourceType: 'Condition',
    id: String(dx.id),
    clinicalStatus: {
      coding: [
        {
          system: 'http://terminology.hl7.org/CodeSystem/condition-clinical',
          code: 'active',
        },
      ],
    },
    verificationStatus: {
      coding: [
        {
          system: 'http://terminology.hl7.org/CodeSystem/condition-ver-status',
          code: 'confirmed',
        },
      ],
    },
    category: [
      {
        coding: [
          {
            system: 'http://terminology.hl7.org/CodeSystem/condition-category',
            code: 'encounter-diagnosis',
            display: 'Encounter Diagnosis',
          },
        ],
      },
    ],
    code: {
      coding: [
        {
          system: 'http://id.who.int/icd/release/11/mms',
          code: dx.icd11_code || 'UNSPECIFIED',
          display: dx.title || dx.condition_name || 'Condition',
        },
      ],
      text: dx.title || dx.condition_name || 'Condition',
    },
    subject: {
      reference: `Patient/${dx.patient_id}`,
    },
    recordedDate: dx.created_at ? new Date(dx.created_at).toISOString() : undefined,
    note: [
      dx.findings ? { text: `Findings: ${dx.findings}` } : null,
      dx.description ? { text: `Description: ${dx.description}` } : null,
      dx.recommended_treatment ? { text: `Treatment: ${dx.recommended_treatment}` } : null,
      dx.additional_notes ? { text: `Notes: ${dx.additional_notes}` } : null,
    ].filter(Boolean),
  };
}

/**
 * Converts conv_prescriptions or standard prescriptions into FHIR MedicationRequest resources.
 */
function prescriptionToFhirRequests(rx, medicines = []) {
  if (!rx) return [];

  const meds = medicines.length > 0 ? medicines : (rx.medicines || []);

  if (meds.length === 0) {
    return [
      {
        resourceType: 'MedicationRequest',
        id: String(rx.id),
        status: 'active',
        intent: 'order',
        subject: { reference: `Patient/${rx.patient_id}` },
        requester: rx.doctor_id ? { reference: `Practitioner/${rx.doctor_id}`, display: rx.doctor_name || undefined } : undefined,
        authoredOn: rx.created_at ? new Date(rx.created_at).toISOString() : undefined,
        medicationCodeableConcept: {
          text: rx.title || 'General Medication Order',
        },
        dosageInstruction: rx.additional_instructions ? [{ patientInstruction: rx.additional_instructions }] : [],
        identifier: rx.signature_hash ? [
          {
            system: 'https://swasthyasathi.gov.np/signature-hash',
            value: rx.signature_hash,
          },
        ] : [],
      },
    ];
  }

  return meds.map((med, idx) => ({
    resourceType: 'MedicationRequest',
    id: `${rx.id}-item-${med.id || idx}`,
    status: 'active',
    intent: 'order',
    subject: {
      reference: `Patient/${rx.patient_id}`,
    },
    requester: rx.doctor_id ? {
      reference: `Practitioner/${rx.doctor_id}`,
      display: rx.doctor_name || undefined,
    } : undefined,
    authoredOn: rx.created_at ? new Date(rx.created_at).toISOString() : undefined,
    medicationCodeableConcept: {
      text: med.medicine_name,
      coding: [
        {
          system: 'https://who.int/atc',
          code: med.atc_code || 'UNSPECIFIED',
          display: med.medicine_name,
        },
      ],
    },
    dosageInstruction: [
      {
        text: [med.dosage, med.frequency, med.duration].filter(Boolean).join(' - '),
        patientInstruction: med.instructions || rx.additional_instructions || undefined,
      },
    ],
    identifier: rx.signature_hash ? [
      {
        system: 'https://swasthyasathi.gov.np/signature-hash',
        value: rx.signature_hash,
      },
    ] : [],
  }));
}

/**
 * Converts blood pressure reading to FHIR Observation.
 */
function bloodPressureToFhir(bp) {
  if (!bp) return null;

  return {
    resourceType: 'Observation',
    id: `bp-${bp.id}`,
    status: 'final',
    category: [
      {
        coding: [
          {
            system: 'http://terminology.hl7.org/CodeSystem/observation-category',
            code: 'vital-signs',
            display: 'Vital Signs',
          },
        ],
      },
    ],
    code: {
      coding: [
        {
          system: 'http://loinc.org',
          code: '85354-9',
          display: 'Blood pressure panel with all children optional',
        },
      ],
      text: 'Blood Pressure',
    },
    subject: {
      reference: `Patient/${bp.patient_id}`,
    },
    effectiveDateTime: bp.reading_date || bp.created_at ? new Date(bp.reading_date || bp.created_at).toISOString() : undefined,
    component: [
      {
        code: {
          coding: [{ system: 'http://loinc.org', code: '8480-6', display: 'Systolic blood pressure' }],
        },
        valueQuantity: {
          value: Number(bp.systolic),
          unit: 'mmHg',
          system: 'http://unitsofmeasure.org',
          code: 'mm[Hg]',
        },
      },
      {
        code: {
          coding: [{ system: 'http://loinc.org', code: '8462-4', display: 'Diastolic blood pressure' }],
        },
        valueQuantity: {
          value: Number(bp.diastolic),
          unit: 'mmHg',
          system: 'http://unitsofmeasure.org',
          code: 'mm[Hg]',
        },
      },
    ],
  };
}

/**
 * Converts blood glucose reading to FHIR Observation.
 */
function glucoseToFhir(gl) {
  if (!gl) return null;

  return {
    resourceType: 'Observation',
    id: `glu-${gl.id}`,
    status: 'final',
    category: [
      {
        coding: [
          {
            system: 'http://terminology.hl7.org/CodeSystem/observation-category',
            code: 'vital-signs',
            display: 'Vital Signs',
          },
        ],
      },
    ],
    code: {
      coding: [
        {
          system: 'http://loinc.org',
          code: '2339-0',
          display: 'Glucose [Mass/volume] in Blood',
        },
      ],
      text: `Blood Glucose (${gl.meal_context || 'Random'})`,
    },
    subject: {
      reference: `Patient/${gl.patient_id}`,
    },
    effectiveDateTime: gl.reading_date || gl.created_at ? new Date(gl.reading_date || gl.created_at).toISOString() : undefined,
    valueQuantity: {
      value: Number(gl.glucose_level),
      unit: 'mg/dL',
      system: 'http://unitsofmeasure.org',
      code: 'mg/dL',
    },
  };
}

/**
 * Wraps resources into a FHIR Bundle.
 */
function buildFhirBundle(resources = [], patientId) {
  const entries = resources.filter(Boolean).map((res) => ({
    fullUrl: `urn:uuid:${res.id}`,
    resource: res,
  }));

  return {
    resourceType: 'Bundle',
    type: 'searchset',
    timestamp: new Date().toISOString(),
    total: entries.length,
    entry: entries,
  };
}

module.exports = {
  patientToFhir,
  appointmentToFhir,
  diagnosisToFhir,
  prescriptionToFhirRequests,
  bloodPressureToFhir,
  glucoseToFhir,
  buildFhirBundle,
};
