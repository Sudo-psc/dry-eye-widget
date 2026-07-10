export type ScientificReference = {
  shortName: string;
  category: string;
  authors: string;
  title: string;
  journal: string;
  year: number;
  doi: string;
};

// Curated primary papers and consensus reports used by the public scientific
// narrative. DOI links are deliberately explicit so every claim can be traced.
export const scientificReferences: ScientificReference[] = [
  {
    shortName: "TFOS DEWS III",
    category: "Current consensus",
    authors: "Perez VL, Chen W, Craig JP, et al.",
    title: "TFOS DEWS III: Executive Summary",
    journal: "American Journal of Ophthalmology",
    year: 2026,
    doi: "10.1016/j.ajo.2025.09.035",
  },
  {
    shortName: "AAO PPP",
    category: "Clinical guideline",
    authors: "Amescua G, Ahmad S, Cheung AY, et al.",
    title: "Dry Eye Syndrome Preferred Practice Pattern®",
    journal: "Ophthalmology",
    year: 2024,
    doi: "10.1016/j.ophtha.2023.12.041",
  },
  {
    shortName: "TFOS DEWS II",
    category: "Definition",
    authors: "Craig JP, Nichols KK, Akpek EK, et al.",
    title: "TFOS DEWS II Definition and Classification Report",
    journal: "The Ocular Surface",
    year: 2017,
    doi: "10.1016/j.jtos.2017.05.008",
  },
  {
    shortName: "Tear film",
    category: "Physiology",
    authors: "Willcox MDP, Argüeso P, Georgiev GA, et al.",
    title: "TFOS DEWS II Tear Film Report",
    journal: "The Ocular Surface",
    year: 2017,
    doi: "10.1016/j.jtos.2017.03.006",
  },
  {
    shortName: "Osaka Study",
    category: "Digital work",
    authors: "Uchino M, Yokoi N, Uchino Y, et al.",
    title: "Prevalence of dry eye disease and its risk factors in visual display terminal users",
    journal: "American Journal of Ophthalmology",
    year: 2013,
    doi: "10.1016/j.ajo.2013.05.040",
  },
  {
    shortName: "VDT meta-analysis",
    category: "Epidemiology",
    authors: "Courtin R, Pereira B, Naughton G, et al.",
    title: "Prevalence of dry eye disease in visual display terminal workers: a systematic review and meta-analysis",
    journal: "BMJ Open",
    year: 2016,
    doi: "10.1136/bmjopen-2015-009675",
  },
  {
    shortName: "Blink behavior",
    category: "Mechanism",
    authors: "Portello JK, Rosenfield M, Chu CA",
    title: "Blink rate, incomplete blinks and computer vision syndrome",
    journal: "Optometry and Vision Science",
    year: 2013,
    doi: "10.1097/OPX.0b013e31828f09a7",
  },
  {
    shortName: "Work productivity",
    category: "Occupational health",
    authors: "Nichols KK, Bacharach J, Holland E, et al.",
    title: "Impact of Dry Eye Disease on Work Productivity",
    journal: "Investigative Ophthalmology & Visual Science",
    year: 2016,
    doi: "10.1167/iovs.16-19419",
  },
  {
    shortName: "Moriguchi Study",
    category: "Occupational screening",
    authors: "Kawashima M, Yamatsuji M, Yokoi N, et al.",
    title: "Screening of dry eye disease in visual display terminal workers during occupational health examinations",
    journal: "Journal of Occupational Health",
    year: 2015,
    doi: "10.1539/joh.14-0243-OA",
  },
  {
    shortName: "Prolonged reading",
    category: "Visual function",
    authors: "Karakus S, Mathews PM, Agrawal D, et al.",
    title: "Impact of Dry Eye on Prolonged Reading",
    journal: "Optometry and Vision Science",
    year: 2018,
    doi: "10.1097/OPX.0000000000001303",
  },
  {
    shortName: "20-20-20 study",
    category: "Behavioral support",
    authors: "Talens-Estarelles C, Cerviño A, García-Lázaro S, et al.",
    title: "The effects of breaks on digital eye strain, dry eye and binocular vision: Testing the 20-20-20 rule",
    journal: "Contact Lens and Anterior Eye",
    year: 2023,
    doi: "10.1016/j.clae.2022.101744",
  },
  {
    shortName: "Blink software RCT",
    category: "Digital intervention",
    authors: "Ashwini DL, Ramesh SV, Nosch D, Wilmot N",
    title: "Efficacy of blink software in improving blink rate and dry eye symptoms in visual display terminal users",
    journal: "Indian Journal of Ophthalmology",
    year: 2021,
    doi: "10.4103/ijo.IJO_3405_20",
  },
];
