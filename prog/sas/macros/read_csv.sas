/*****************************************************************************************************************
 SAS file name: macros.sas
__________________________________________________________________________________________________________________

Purpose: Respository of Macros for the CPRD DPP4i project
Author: Jeanny Wang
Creation Date: 23 SEPT 23

    Program and output path:
        Program Path
        D:\Externe Projekte\UNC\wangje\code\macros

    Input paths: NA

Other details: NA
__________________________________________________________________________________________________________________

CHANGES:
Date: 23SEPT23
Notes: initial commit. see change log at https://github.com/scscriptionsh/dpp4i-cprd.
*****************************************************************************************************************/

/*read_csv*/
*Macro for reading in CSV files into a sas7bdat format for analysis;
%macro read_csv ( inpath , outlib , outname   );

        data &outlib..sensitivityA_&outname.;
            infile "&inpath."
            dlm=';'  firstobs=2 dsd  missover pad truncover end=eol;
            input
            id	: $12.
            code	$
            entry	: ddmmyy10.
            exit	: ddmmyy10.
            cohortdays
            age
            age1
            sex	$
            smoke	$
            smoketime
            heighttime
            heightt
            weight
            weighttime
            bmi
            bmitime
            alc	$
            alcstattime
            alcunit
            unitavg
            hba1c
            hba1ctime
            Nohba1c
            hba1cavg
            history
            caco
            exp
            GPyearDx
            GPyearDxRx
            asthma_bc	$
            asthma_bl
            copd_bc	$
            copd_bl
            arrhyth_bc	$
            arrhyth_bl
            chf_bc	$
            chf_bl
            ihd_bc	$
            ihd_bl
            mi_bc	$
            mi_bl
            hyperten_bc	$
            hyperten_bl
            stroke_bc	$
            stroke_bl
            hyperlip_bc	$
            hyperlip_bl
            diab_bc	$
            diab_bl
            dvt_bc	$
            dvt_bl
            pe_bc	$
            pe_bl
            gout_bc	$
            gout_bl
            pthyro_bc	$
            pthyro_bl
            mthyro_bc	$
            mthyro_bl
            depres_bc	$
            depres_bl
            affect_bc	$
            affect_bl
            suic_bc	$
            suic_bl
            sleep_bc	$
            sleep_bl
            schizo_bc	$
            schizo_bl
            epilep_bc	$
            epilep_bl
            renal_bc	$
            renal_bl
            gIulcer_bc	$
            gIulcer_bl
            ra_bc	$
            ra_bl
            alrhi_bc	$
            alrhi_bl
            glauco_bc	$
            glauco_bl
            migra_bc	$
            migra_bl
            sepsis_bc	$
            sepsis_bl
            pneumo_bc	$
            pneumo_bl
            nephr_bc	$
            nephr_bl
            nerop_bc	$
            nerop_bl
            dret_bc	$
            dret_bl
            psorI_bc	$
            psorI_bl
            psorP_bc	$
            psorP_bl
            vasc_bc	$
            vasc_bl
            sjogr_bc	$
            sjogr_bl
            sle_bc	$
            sle_bl
            pad_bc	$
            pad_bl
            abdp_bc	$
            abdp_bl
            diarr_bc	$
            diarr_bl
            bstools_bc	$
            bstools_bl
            CD_bc	$
            CD_bl
            UC_bc	$
            UC_bl
            IC_bc	$
            IC_bl
            refendo_bc	$
            refendo_bl
            refgastro_bc	$
            refgastro_bl
            stomy_bc	$
            stomy_bl
            sigmoid_bc	$
            sigmoid_bl
            bx_bc	$
            bx_bl
            ileostomy_bc	$
            ileostomy_bl
            IBD_bc	$
            IBD_bl
            divertic_bc	$
            divertic_bl
            ace_tot
            ace_last
            ace_first
            ace_code	: $9.
            arb_tot
            arb_last
            arb_first
            arb_code	: $9.
            bb_tot
            bb_last
            bb_first
            bb_code	: $9.
            ccb_tot
            ccb_last
            ccb_first
            ccb_code	: $9.
            nitrat_tot
            nitrat_last
            nitrat_first
            nitrat_code	: $9.
            coronar_tot
            coronar_last
            coronar_first
            coronar_code	: $9.
            antiarr_tot
            antiarr_last
            antiarr_first
            antiarr_code	: $9.
            thrombo_tot
            thrombo_last
            thrombo_first
            thrombo_code	: $9.
            antivitk_tot
            antivitk_last
            antivitk_first
            antivitk_code	: $9.
            hepar_tot
            hepar_last
            hepar_first
            hepar_code	: $9.
            insul_tot
            insul_last
            insul_first
            insul_code	: $9.
            sulfon_tot
            sulfon_last
            sulfon_first
            sulfon_code	: $9.
            bigua_tot
            bigua_last
            bigua_first
            bigua_code	: $9.
            ppar_tot
            ppar_last
            ppar_first
            ppar_code	: $9.
            prand_tot
            prand_last
            prand_first
            prand_code	: $9.
            agluco_tot
            agluco_last
            agluco_first
            agluco_code	: $9.
            adiabc_tot
            adiabc_last
            adiabc_first
            adiabc_code	: $9.
            oadiab_tot
            oadiab_last
            oadiab_first
            oadiab_code	: $9.
            alloadiab_tot
            alloadiab_last
            alloadiab_first
            alloadiab_code	: $9.
            alladiab_tot
            alladiab_last
            alladiab_first
            alladiab_code	: $9.
            stat_tot
            stat_last
            stat_first
            stat_code	: $9.
            fib_tot
            fib_last
            fib_first
            fib_code	: $9.
            lla_tot
            lla_last
            lla_first
            lla_code	: $9.
            thiaz_tot
            thiaz_last
            thiaz_first
            thiaz_code	: $9.
            loop_tot
            loop_last
            loop_first
            loop_code	: $9.
            kspar_tot
            kspar_last
            kspar_first
            kspar_code	: $9.
            diurcom_tot
            diurcom_last
            diurcom_first
            diurcom_code	: $9.
            thiaantih_tot
            thiaantih_last
            thiaantih_first
            thiaantih_code	: $9.
            diurall_tot
            diurall_last
            diurall_first
            diurall_code	: $9.
            ass_tot
            ass_last
            ass_first
            ass_code	: $9.
            cox2_tot
            cox2_last
            cox2_first
            cox2_code	: $9.
            diclo_tot
            diclo_last
            diclo_first
            diclo_code	: $9.
            ibu_tot
            ibu_last
            ibu_first
            ibu_code	: $9.
            napro_tot
            napro_last
            napro_first
            napro_code	: $9.
            otnsa_tot
            otnsa_last
            otnsa_first
            otnsa_code	: $9.
            para_tot
            para_last
            para_first
            para_code	: $9.
            allnsa_tot
            allnsa_last
            allnsa_first
            allnsa_code	: $9.
            opio_tot
            opio_last
            opio_first
            opio_code	: $9.
            acho_tot
            acho_last
            acho_first
            acho_code	: $9.
            sterinh_tot
            sterinh_last
            sterinh_first
            sterinh_code	: $9.
            bago_tot
            bago_last
            bago_first
            bago_code	: $9.
            abago_tot
            abago_last
            abago_first
            abago_code	: $9.
            lra_tot
            lra_last
            lra_first
            lra_code	: $9.
            xant_tot
            xant_last
            xant_first
            xant_code	: $9.
            ahist_tot
            ahist_last
            ahist_first
            ahist_code	: $9.
            ahistc_tot
            ahistc_last
            ahistc_first
            ahistc_code	: $9.
            h2_tot
            h2_last
            h2_first
            h2_code	: $9.
            ppi_tot
            ppi_last
            ppi_first
            ppi_code	: $9.
            IBD_tot
            IBD_last
            IBD_first
            IBD_code	: $9.
            thyro_tot
            thyro_last
            thyro_first
            thyro_code	: $9.
            sterint_tot
            sterint_last
            sterint_first
            sterint_code	: $9.
            stersys_tot
            stersys_last
            stersys_first
            stersys_code	: $9.
            stertop_tot
            stertop_last
            stertop_first
            stertop_code	: $9.
            gesta_tot
            gesta_last
            gesta_first
            gesta_code	: $9.
            pill_tot
            pill_last
            pill_first
            pill_code	: $9.
            adem_tot
            adem_last
            adem_first
            adem_code	: $9.
            apsy_tot
            apsy_last
            apsy_first
            apsy_code	: $9.
            benzo_tot
            benzo_last
            benzo_first
            benzo_code	: $9.
            hypno_tot
            hypno_last
            hypno_first
            hypno_code	: $9.
            ssri_tot
            ssri_last
            ssri_first
            ssri_code	: $9.
            li_tot
            li_last
            li_first
            li_code	: $9.
            mao_tot
            mao_last
            mao_first
            mao_code	: $9.
            oadep_tot
            oadep_last
            oadep_first
            oadep_code	: $9.
            mnri_tot
            mnri_last
            mnri_first
            mnri_code	: $9.
            adep_tot
            adep_last
            adep_first
            adep_code	: $9.
            pheny_tot
            pheny_last
            pheny_first
            pheny_code	: $9.
            barbi_tot
            barbi_last
            barbi_first
            barbi_code	: $9.
            succi_tot
            succi_last
            succi_first
            succi_code	: $9.
            valpro_tot
            valpro_last
            valpro_first
            valpro_code	: $9.
            carba_tot
            carba_last
            carba_first
            carba_code	: $9.
            oaconvu_tot
            oaconvu_last
            oaconvu_first
            oaconvu_code	: $9.
            aconvu_tot
            aconvu_last
            aconvu_first
            aconvu_code	: $9.
            isupp_tot
            isupp_last
            isupp_first
            isupp_code	: $9.
            dpp4i_tot
            dpp4i_last
            dpp4i_first
            dpp4i_code	: $9.
            sulfonyl_tot
            sulfonyl_last
            sulfonyl_first
            sulfonyl_code	: $9.
            sglt2i_tot
            sglt2i_last
            sglt2i_first
            sglt2i_code	: $9.
            TZD_tot
            TZD_last
            TZD_first
            TZD_code	: $9.
            GLP1_tot
            GLP1_last
            GLP1_first
            GLP1_code	: $9.
            metformin_tot
            metformin_last
            metformin_first
            metformin_code	: $9.
            sitagliptin_tot
            sitagliptin_last
            sitagliptin_first
            sitagliptin_code	: $9.
            vildagliptin_tot
            vildagliptin_last
            vildagliptin_first
            vildagliptin_code	: $9.
            saxagliptin_tot
            saxagliptin_last
            saxagliptin_first
            saxagliptin_code	: $9.
            linagliptin_tot
            linagliptin_last
            linagliptin_first
            linagliptin_code	: $9.
            alogliptin_tot
            alogliptin_last
            alogliptin_first
            alogliptin_code	: $9.
            ASA_tot
            ASA_last
            ASA_first
            ASA_code	: $9.
            mesala_tot
            mesala_last
            mesala_first
            mesala_code	: $9.
            sulfasala_tot
            sulfasala_last
            sulfasala_first
            sulfasala_code	: $9.
            olsala_tot
            olsala_last
            olsala_first
            olsala_code	: $9.
            balsala_tot
            balsala_last
            balsala_first
            balsala_code	: $9.
            meglitinide_tot
            meglitinide_last
            meglitinide_first
            meglitinide_code	: $9.
            HRTopp_tot
            HRTopp_last
            HRTopp_first
            HRTopp_code	: $9.
            HRToverall_tot
            HRToverall_last
            HRToverall_first
            HRToverall_code	: $9.
            TNFai_tot
            TNFai_last
            TNFai_first
            TNFai_code	: $9.
            budes_tot
            budes_last
            budes_first
            budes_code	: $9.
            Adcombo_tot
            Adcombo_last
            Adcombo_first
            Adcombo_code	: $9.
            immureg_tot
            immureg_last
            immureg_first
            immureg_code	: $9.
            cyclosp_tot
            cyclosp_last
            cyclosp_first
            cyclosp_code	: $9.
            timep
            tx_at_timep
            start
            stop
            startstop
            tx_status
            exit_reason
/*            EOL	$*/


            ;
            label id="unique ID";
            label code="READ code of first-time outcome of interest at cohort exit date";
            label entry="Cohort entry date";
            label exit="Cohort exit date";
            label cohortdays="Days between cohort entry and cohort exit";
            label age="Age at cohort entry date";
            label age1="Age at time of first prescription of DPP4i or comparator drug prior to cohort entry";
            label sex="Sex (m=male, f=female)";
            label smoke="Last smoking status prior to (including) CED";
            label smoketime="  .. number of days before including CED";
            label heighttime="Height (closest recording prior to the index date, if not found then the first recording after the index date)";
            label heightt="Height/time (number of days between the last recording before the index date [or the first recording after the i.d.-> negative values] and the index date)";
            label weight="Weight (closest recording prior to the index date)";
            label weighttime="Weight/time (number of days between the last recording before the index date and the index date)";
            label bmi="BMI (closest recording prior to the index date)";
            label bmitime="BMI/time (number of days between the last recording before the index date and the index date)";
            label alc="Last alcohol status prior to the index date (u = unknown, c = current, n = never, ex = ex) If not found: the first recording within three years after the index date)";
            label alcstattime="Last alcohol status prior to the index date/time (number of days between the last recording before the index date [or the first recording after the i.d.] and the index date)";
            label alcunit="Units per week for recorded value of last alcohol status prior the index date (if not found the first recording within three years after the index date)";
            label unitavg="Average units per week for all recorded alcohol units prior the index date";
            label hba1c="HBA1c level in mmol/mol (HBA1c_level.txt) before index date (closest recording prior to the index date)";
            label hba1ctime="HBA1c level/time (number of days between the last recording before the index date and the index date)";
            label Nohba1c="Number of HBA1c recordings within the last three years prior to the index date)";
            label hba1cavg="Average HBA1c level within the last three years before the index date";
            label history="Number of days of recorded history in the database prior to the cohort entry date";
            label caco="Outcome status (1=case, 0=control)";
            label exp="Exposure status (1 = exposed, 0 = unexposed)";
            label GPyearDx="Practice visits last year (based on diagnoses only)";
            label GPyearDxRx="Practice visits last year (based on diagnoses and prescripions)";
            label asthma_bc="asthma_bc: ASTHMA_P.TXT ... Last read code before (excluding) cohort entry date";
            label asthma_bl="asthma_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label copd_bc="copd_bc: COPD_P.TXT ... Last read code before (excluding) cohort entry date";
            label copd_bl="copd_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label arrhyth_bc="arrhyth_bc: ARRHYTHMIA_P.TXT ... Last read code before (excluding) cohort entry date";
            label arrhyth_bl="arrhyth_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label chf_bc="chf_bc: HEART FAILURE_P.TXT ... Last read code before (excluding) cohort entry date";
            label chf_bl="chf_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label ihd_bc="ihd_bc: IHD WITHOUT MI_P.TXT ... Last read code before (excluding) cohort entry date";
            label ihd_bl="ihd_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label mi_bc="mi_bc: MYOCARDIAL INFARCTION_P.TXT ... Last read code before (excluding) cohort entry date";
            label mi_bl="mi_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label hyperten_bc="hyperten_bc: HYPERTENSION_P.TXT ... Last read code before (excluding) cohort entry date";
            label hyperten_bl="hyperten_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label stroke_bc="stroke_bc: STROKES_ALL_WITH TIA_P.TXT ... Last read code before (excluding) cohort entry date";
            label stroke_bl="stroke_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label hyperlip_bc="hyperlip_bc: HYPERLIPIDEMIA_P.TXT ... Last read code before (excluding) cohort entry date";
            label hyperlip_bl="hyperlip_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label diab_bc="diab_bc: DIABETES_P.TXT ... Last read code before (excluding) cohort entry date";
            label diab_bl="diab_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label dvt_bc="dvt_bc: DVT_P.TXT ... Last read code before (excluding) cohort entry date";
            label dvt_bl="dvt_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label pe_bc="pe_bc: PULMONARY EMBOLISM_P.TXT ... Last read code before (excluding) cohort entry date";
            label pe_bl="pe_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label gout_bc="gout_bc: GOUT AND HYPERURICEMIA_P.TXT ... Last read code before (excluding) cohort entry date";
            label gout_bl="gout_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label pthyro_bc="pthyro_bc: HYPERTHYROIDISM_P.TXT ... Last read code before (excluding) cohort entry date";
            label pthyro_bl="pthyro_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label mthyro_bc="mthyro_bc: HYPOTHYROIDISM_P.TXT ... Last read code before (excluding) cohort entry date";
            label mthyro_bl="mthyro_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label depres_bc="depres_bc: DEPRESSION_ONLY_P.TXT ... Last read code before (excluding) cohort entry date";
            label depres_bl="depres_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label affect_bc="affect_bc: AFFECTIVE DISORDERS_WTHDEPRESSION_P.TXT ... Last read code before (excluding) cohort entry date";
            label affect_bl="affect_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label suic_bc="suic_bc: SUICIDE AND SUICIDAL IDEATION_P.TXT ... Last read code before (excluding) cohort entry date";
            label suic_bl="suic_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label sleep_bc="sleep_bc: SLEEP DISORDERS_P.TXT ... Last read code before (excluding) cohort entry date";
            label sleep_bl="sleep_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label schizo_bc="schizo_bc: SCHIZOPHRENIC, SCHIZOTYPAL AND DELUSIONAL DISORDERS_P.TXT ... Last read code before (excluding) cohort entry date";
            label schizo_bl="schizo_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label epilep_bc="epilep_bc: EPILEPSY_P.TXT ... Last read code before (excluding) cohort entry date";
            label epilep_bl="epilep_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label renal_bc="renal_bc: RENAL DISEASES_P.TXT ... Last read code before (excluding) cohort entry date";
            label renal_bl="renal_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label gIulcer_bc="gIulcer_bc: ULCER_P.TXT ... Last read code before (excluding) cohort entry date";
            label gIulcer_bl="gIulcer_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label ra_bc="ra_bc: RHEUMATOID ARTHRITIS_P.TXT ... Last read code before (excluding) cohort entry date";
            label ra_bl="ra_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label alrhi_bc="alrhi_bc: ALLERGIC RHINOCONJUNCTIVITIS_HAY FEVER_P.TXT ... Last read code before (excluding) cohort entry date";
            label alrhi_bl="alrhi_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label glauco_bc="glauco_bc: GLAUCOMA_P.TXT ... Last read code before (excluding) cohort entry date";
            label glauco_bl="glauco_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label migra_bc="migra_bc: MIGRAINE_P.TXT ... Last read code before (excluding) cohort entry date";
            label migra_bl="migra_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label sepsis_bc="sepsis_bc: SEPSIS_P.TXT ... Last read code before (excluding) cohort entry date";
            label sepsis_bl="sepsis_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label pneumo_bc="pneumo_bc: PNEUMONIA_P.TXT ... Last read code before (excluding) cohort entry date";
            label pneumo_bl="pneumo_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label nephr_bc="nephr_bc: NEPHROPATHY.TXT ... Last read code before (excluding) cohort entry date";
            label nephr_bl="nephr_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label nerop_bc="nerop_bc: NEUROPATHY.TXT ... Last read code before (excluding) cohort entry date";
            label nerop_bl="nerop_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label dret_bc="dret_bc: DIABETIC_RETINOPATHY_P.TXT ... Last read code before (excluding) cohort entry date";
            label dret_bl="dret_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label psorI_bc="psorI_bc: PSORIASIS_I.TXT ... Last read code before (excluding) cohort entry date";
            label psorI_bl="psorI_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label psorP_bc="psorP_bc: PSORIASIS_P.TXT ... Last read code before (excluding) cohort entry date";
            label psorP_bl="psorP_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label vasc_bc="vasc_bc: VASCULITIS_P.TXT ... Last read code before (excluding) cohort entry date";
            label vasc_bl="vasc_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label sjogr_bc="sjogr_bc: SJOGREN SYNDROM_P.TXT ... Last read code before (excluding) cohort entry date";
            label sjogr_bl="sjogr_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label sle_bc="sle_bc: SYSTEMIC LUPUS ERYTHEMATODES_P.TXT ... Last read code before (excluding) cohort entry date";
            label sle_bl="sle_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label pad_bc="pad_bc: PERIPHERAL ARTERIAL DISEASE.TXT ... Last read code before (excluding) cohort entry date";
            label pad_bl="pad_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label abdp_bc="abdp_bc: ABDOMINAL PAIN.TXT ... Last read code before (excluding) cohort entry date";
            label abdp_bl="abdp_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label diarr_bc="diarr_bc: DIARRHOEA.TXT ... Last read code before (excluding) cohort entry date";
            label diarr_bl="diarr_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label bstools_bc="bstools_bc: BLOODY STOOLS.TXT ... Last read code before (excluding) cohort entry date";
            label bstools_bl="bstools_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label CD_bc="CD_bc: CROHNS DISEASE.TXT ... Last read code before (excluding) cohort entry date";
            label CD_bl="CD_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label UC_bc="UC_bc: ULCERATIVE COLITIS.TXT ... Last read code before (excluding) cohort entry date";
            label UC_bl="UC_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label IC_bc="IC_bc: ISCHAEMIC COLITIS_P.TXT ... Last read code before (excluding) cohort entry date";
            label IC_bl="IC_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label refendo_bc="refendo_bc: ENDOSCOPY.TXT ... Last read code before (excluding) cohort entry date";
            label refendo_bl="refendo_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label refgastro_bc="refgastro_bc: GASTROENTEROLOGY.TXT ... Last read code before (excluding) cohort entry date";
            label refgastro_bl="refgastro_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label stomy_bc="stomy_bc: COLECTOMY AND ILEOSTOMY.TXT ... Last read code before (excluding) cohort entry date";
            label stomy_bl="stomy_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label sigmoid_bc="sigmoid_bc: SIGMOIDOSCOPY.TXT ... Last read code before (excluding) cohort entry date";
            label sigmoid_bl="sigmoid_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label bx_bc="bx_bc: BIOPSY.TXT ... Last read code before (excluding) cohort entry date";
            label bx_bl="bx_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label ileostomy_bc="ileostomy_bc: ILEOSTOMY.TXT ... Last read code before (excluding) cohort entry date";
            label ileostomy_bl="ileostomy_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label IBD_bc="IBD_bc: INFLAMMATORY BOWEL DISEASE_I.TXT ... Last read code before (excluding) cohort entry date";
            label IBD_bl="IBD_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label divertic_bc="divertic_bc: DIVERTICULITIS AND COLITIS_I.TXT ... Last read code before (excluding) cohort entry date";
            label divertic_bl="divertic_bl: Days between last date of diagnose and (excluding) cohort entry date";
            label ace_tot="ace_tot: ACE-INHIBITORS.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label ace_last="ace_last: Days between last date of prescription and (excluding) cohort entry date";
            label ace_first="ace_first: Days between first date of prescription and (excluding) cohort entry date";
            label ace_code="ace_code: Last gemscript code before (excluding) cohort entry date";
            label arb_tot="arb_tot: ANGIOTENSIN II ANTAGONISTS.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label arb_last="arb_last: Days between last date of prescription and (excluding) cohort entry date";
            label arb_first="arb_first: Days between first date of prescription and (excluding) cohort entry date";
            label arb_code="arb_code: Last gemscript code before (excluding) cohort entry date";
            label bb_tot="bb_tot: BETABLOCKERS W THIAZIDES.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label bb_last="bb_last: Days between last date of prescription and (excluding) cohort entry date";
            label bb_first="bb_first: Days between first date of prescription and (excluding) cohort entry date";
            label bb_code="bb_code: Last gemscript code before (excluding) cohort entry date";
            label ccb_tot="ccb_tot: CALCIUM CHANNEL BLOCKER.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label ccb_last="ccb_last: Days between last date of prescription and (excluding) cohort entry date";
            label ccb_first="ccb_first: Days between first date of prescription and (excluding) cohort entry date";
            label ccb_code="ccb_code: Last gemscript code before (excluding) cohort entry date";
            label nitrat_tot="nitrat_tot: NITRATES.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label nitrat_last="nitrat_last: Days between last date of prescription and (excluding) cohort entry date";
            label nitrat_first="nitrat_first: Days between first date of prescription and (excluding) cohort entry date";
            label nitrat_code="nitrat_code: Last gemscript code before (excluding) cohort entry date";
            label coronar_tot="coronar_tot: CORONARY VASODILATATORS.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label coronar_last="coronar_last: Days between last date of prescription and (excluding) cohort entry date";
            label coronar_first="coronar_first: Days between first date of prescription and (excluding) cohort entry date";
            label coronar_code="coronar_code: Last gemscript code before (excluding) cohort entry date";
            label antiarr_tot="antiarr_tot: ANTIARRHYTHMICS.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label antiarr_last="antiarr_last: Days between last date of prescription and (excluding) cohort entry date";
            label antiarr_first="antiarr_first: Days between first date of prescription and (excluding) cohort entry date";
            label antiarr_code="antiarr_code: Last gemscript code before (excluding) cohort entry date";
            label thrombo_tot="thrombo_tot: ANTIPLATELETS.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label thrombo_last="thrombo_last: Days between last date of prescription and (excluding) cohort entry date";
            label thrombo_first="thrombo_first: Days between first date of prescription and (excluding) cohort entry date";
            label thrombo_code="thrombo_code: Last gemscript code before (excluding) cohort entry date";
            label antivitk_tot="antivitk_tot: VITAMIN K ANTAGONISTS.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label antivitk_last="antivitk_last: Days between last date of prescription and (excluding) cohort entry date";
            label antivitk_first="antivitk_first: Days between first date of prescription and (excluding) cohort entry date";
            label antivitk_code="antivitk_code: Last gemscript code before (excluding) cohort entry date";
            label hepar_tot="hepar_tot: HEPARINS.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label hepar_last="hepar_last: Days between last date of prescription and (excluding) cohort entry date";
            label hepar_first="hepar_first: Days between first date of prescription and (excluding) cohort entry date";
            label hepar_code="hepar_code: Last gemscript code before (excluding) cohort entry date";
            label insul_tot="insul_tot: INSULIN.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label insul_last="insul_last: Days between last date of prescription and (excluding) cohort entry date";
            label insul_first="insul_first: Days between first date of prescription and (excluding) cohort entry date";
            label insul_code="insul_code: Last gemscript code before (excluding) cohort entry date";
            label sulfon_tot="sulfon_tot: ORAL ANTIDIABETICS_SULFONYLUREAS.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label sulfon_last="sulfon_last: Days between last date of prescription and (excluding) cohort entry date";
            label sulfon_first="sulfon_first: Days between first date of prescription and (excluding) cohort entry date";
            label sulfon_code="sulfon_code: Last gemscript code before (excluding) cohort entry date";
            label bigua_tot="bigua_tot: ORAL ANTIDIABETICS_BIGUANIDES.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label bigua_last="bigua_last: Days between last date of prescription and (excluding) cohort entry date";
            label bigua_first="bigua_first: Days between first date of prescription and (excluding) cohort entry date";
            label bigua_code="bigua_code: Last gemscript code before (excluding) cohort entry date";
            label ppar_tot="ppar_tot: ORAL ANTIDIABETICS_PPAR AGONISTS.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label ppar_last="ppar_last: Days between last date of prescription and (excluding) cohort entry date";
            label ppar_first="ppar_first: Days between first date of prescription and (excluding) cohort entry date";
            label ppar_code="ppar_code: Last gemscript code before (excluding) cohort entry date";
            label prand_tot="prand_tot: ORAL ANTIDIABETICS_GLINIDES.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label prand_last="prand_last: Days between last date of prescription and (excluding) cohort entry date";
            label prand_first="prand_first: Days between first date of prescription and (excluding) cohort entry date";
            label prand_code="prand_code: Last gemscript code before (excluding) cohort entry date";
            label agluco_tot="agluco_tot: ORAL ANTIDIABETICS_ACARBOSE.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label agluco_last="agluco_last: Days between last date of prescription and (excluding) cohort entry date";
            label agluco_first="agluco_first: Days between first date of prescription and (excluding) cohort entry date";
            label agluco_code="agluco_code: Last gemscript code before (excluding) cohort entry date";
            label adiabc_tot="adiabc_tot: ORAL ANTIDIABETICS_ALL COMBINATIONS.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label adiabc_last="adiabc_last: Days between last date of prescription and (excluding) cohort entry date";
            label adiabc_first="adiabc_first: Days between first date of prescription and (excluding) cohort entry date";
            label adiabc_code="adiabc_code: Last gemscript code before (excluding) cohort entry date";
            label oadiab_tot="oadiab_tot: ORAL ANTIDIABETICS_OTHER.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label oadiab_last="oadiab_last: Days between last date of prescription and (excluding) cohort entry date";
            label oadiab_first="oadiab_first: Days between first date of prescription and (excluding) cohort entry date";
            label oadiab_code="oadiab_code: Last gemscript code before (excluding) cohort entry date";
            label alloadiab_tot="alloadiab_tot: ANTIDIABETICS_NO INSULIN.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label alloadiab_last="alloadiab_last: Days between last date of prescription and (excluding) cohort entry date";
            label alloadiab_first="alloadiab_first: Days between first date of prescription and (excluding) cohort entry date";
            label alloadiab_code="alloadiab_code: Last gemscript code before (excluding) cohort entry date";
            label alladiab_tot="alladiab_tot: ANTIDIABETICS.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label alladiab_last="alladiab_last: Days between last date of prescription and (excluding) cohort entry date";
            label alladiab_first="alladiab_first: Days between first date of prescription and (excluding) cohort entry date";
            label alladiab_code="alladiab_code: Last gemscript code before (excluding) cohort entry date";
            label stat_tot="stat_tot: STATINS.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label stat_last="stat_last: Days between last date of prescription and (excluding) cohort entry date";
            label stat_first="stat_first: Days between first date of prescription and (excluding) cohort entry date";
            label stat_code="stat_code: Last gemscript code before (excluding) cohort entry date";
            label fib_tot="fib_tot: FIBRATES.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label fib_last="fib_last: Days between last date of prescription and (excluding) cohort entry date";
            label fib_first="fib_first: Days between first date of prescription and (excluding) cohort entry date";
            label fib_code="fib_code: Last gemscript code before (excluding) cohort entry date";
            label lla_tot="lla_tot: LIPID LOWERING AGENTS OTHER.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label lla_last="lla_last: Days between last date of prescription and (excluding) cohort entry date";
            label lla_first="lla_first: Days between first date of prescription and (excluding) cohort entry date";
            label lla_code="lla_code: Last gemscript code before (excluding) cohort entry date";
            label thiaz_tot="thiaz_tot: THIAZIDE DIURETICS.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label thiaz_last="thiaz_last: Days between last date of prescription and (excluding) cohort entry date";
            label thiaz_first="thiaz_first: Days between first date of prescription and (excluding) cohort entry date";
            label thiaz_code="thiaz_code: Last gemscript code before (excluding) cohort entry date";
            label loop_tot="loop_tot: LOOP DIURETICS.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label loop_last="loop_last: Days between last date of prescription and (excluding) cohort entry date";
            label loop_first="loop_first: Days between first date of prescription and (excluding) cohort entry date";
            label loop_code="loop_code: Last gemscript code before (excluding) cohort entry date";
            label kspar_tot="kspar_tot: KALIUM SPARING DIURETICS.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label kspar_last="kspar_last: Days between last date of prescription and (excluding) cohort entry date";
            label kspar_first="kspar_first: Days between first date of prescription and (excluding) cohort entry date";
            label kspar_code="kspar_code: Last gemscript code before (excluding) cohort entry date";
            label diurcom_tot="diurcom_tot: DIURETICS COMBINATIONS_UNCLASS.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label diurcom_last="diurcom_last: Days between last date of prescription and (excluding) cohort entry date";
            label diurcom_first="diurcom_first: Days between first date of prescription and (excluding) cohort entry date";
            label diurcom_code="diurcom_code: Last gemscript code before (excluding) cohort entry date";
            label thiaantih_tot="thiaantih_tot: THIAZIDES WITH ANTIHYPERTENSIVES.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label thiaantih_last="thiaantih_last: Days between last date of prescription and (excluding) cohort entry date";
            label thiaantih_first="thiaantih_first: Days between first date of prescription and (excluding) cohort entry date";
            label thiaantih_code="thiaantih_code: Last gemscript code before (excluding) cohort entry date";
            label diurall_tot="diurall_tot: DIURETICSALL.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label diurall_last="diurall_last: Days between last date of prescription and (excluding) cohort entry date";
            label diurall_first="diurall_first: Days between first date of prescription and (excluding) cohort entry date";
            label diurall_code="diurall_code: Last gemscript code before (excluding) cohort entry date";
            label ass_tot="ass_tot: ACETYLSALICYLIC ACID.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label ass_last="ass_last: Days between last date of prescription and (excluding) cohort entry date";
            label ass_first="ass_first: Days between first date of prescription and (excluding) cohort entry date";
            label ass_code="ass_code: Last gemscript code before (excluding) cohort entry date";
            label cox2_tot="cox2_tot: NSAIDS_COX2 INHIBITORS.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label cox2_last="cox2_last: Days between last date of prescription and (excluding) cohort entry date";
            label cox2_first="cox2_first: Days between first date of prescription and (excluding) cohort entry date";
            label cox2_code="cox2_code: Last gemscript code before (excluding) cohort entry date";
            label diclo_tot="diclo_tot: NSAIDS_DICLOFENAC.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label diclo_last="diclo_last: Days between last date of prescription and (excluding) cohort entry date";
            label diclo_first="diclo_first: Days between first date of prescription and (excluding) cohort entry date";
            label diclo_code="diclo_code: Last gemscript code before (excluding) cohort entry date";
            label ibu_tot="ibu_tot: NSAIDS_IBUPROFEN.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label ibu_last="ibu_last: Days between last date of prescription and (excluding) cohort entry date";
            label ibu_first="ibu_first: Days between first date of prescription and (excluding) cohort entry date";
            label ibu_code="ibu_code: Last gemscript code before (excluding) cohort entry date";
            label napro_tot="napro_tot: NSAIDS_NAPROXEN.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label napro_last="napro_last: Days between last date of prescription and (excluding) cohort entry date";
            label napro_first="napro_first: Days between first date of prescription and (excluding) cohort entry date";
            label napro_code="napro_code: Last gemscript code before (excluding) cohort entry date";
            label otnsa_tot="otnsa_tot: NSAIDS_OTHER NSAIDS.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label otnsa_last="otnsa_last: Days between last date of prescription and (excluding) cohort entry date";
            label otnsa_first="otnsa_first: Days between first date of prescription and (excluding) cohort entry date";
            label otnsa_code="otnsa_code: Last gemscript code before (excluding) cohort entry date";
            label para_tot="para_tot: PARACETAMOL.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label para_last="para_last: Days between last date of prescription and (excluding) cohort entry date";
            label para_first="para_first: Days between first date of prescription and (excluding) cohort entry date";
            label para_code="para_code: Last gemscript code before (excluding) cohort entry date";
            label allnsa_tot="allnsa_tot: NSAIDS_ALL_NEW.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label allnsa_last="allnsa_last: Days between last date of prescription and (excluding) cohort entry date";
            label allnsa_first="allnsa_first: Days between first date of prescription and (excluding) cohort entry date";
            label allnsa_code="allnsa_code: Last gemscript code before (excluding) cohort entry date";
            label opio_tot="opio_tot: OPIOIDS_ALL.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label opio_last="opio_last: Days between last date of prescription and (excluding) cohort entry date";
            label opio_first="opio_first: Days between first date of prescription and (excluding) cohort entry date";
            label opio_code="opio_code: Last gemscript code before (excluding) cohort entry date";
            label acho_tot="acho_tot: ANTICHOLINERGICS COPD.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label acho_last="acho_last: Days between last date of prescription and (excluding) cohort entry date";
            label acho_first="acho_first: Days between first date of prescription and (excluding) cohort entry date";
            label acho_code="acho_code: Last gemscript code before (excluding) cohort entry date";
            label sterinh_tot="sterinh_tot: CORTICOSTEROIDS-INHAL.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label sterinh_last="sterinh_last: Days between last date of prescription and (excluding) cohort entry date";
            label sterinh_first="sterinh_first: Days between first date of prescription and (excluding) cohort entry date";
            label sterinh_code="sterinh_code: Last gemscript code before (excluding) cohort entry date";
            label bago_tot="bago_tot: BETA-AGONISTS.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label bago_last="bago_last: Days between last date of prescription and (excluding) cohort entry date";
            label bago_first="bago_first: Days between first date of prescription and (excluding) cohort entry date";
            label bago_code="bago_code: Last gemscript code before (excluding) cohort entry date";
            label abago_tot="abago_tot: ALPHA AND BETA AGONISTS.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label abago_last="abago_last: Days between last date of prescription and (excluding) cohort entry date";
            label abago_first="abago_first: Days between first date of prescription and (excluding) cohort entry date";
            label abago_code="abago_code: Last gemscript code before (excluding) cohort entry date";
            label lra_tot="lra_tot: LEUKOTRIENE RECEPTOR ANTAGONISTS.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label lra_last="lra_last: Days between last date of prescription and (excluding) cohort entry date";
            label lra_first="lra_first: Days between first date of prescription and (excluding) cohort entry date";
            label lra_code="lra_code: Last gemscript code before (excluding) cohort entry date";
            label xant_tot="xant_tot: XANTHINES.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label xant_last="xant_last: Days between last date of prescription and (excluding) cohort entry date";
            label xant_first="xant_first: Days between first date of prescription and (excluding) cohort entry date";
            label xant_code="xant_code: Last gemscript code before (excluding) cohort entry date";
            label ahist_tot="ahist_tot: HISTAMINE ANTAGONISTS_WITHOUT COMBIS.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label ahist_last="ahist_last: Days between last date of prescription and (excluding) cohort entry date";
            label ahist_first="ahist_first: Days between first date of prescription and (excluding) cohort entry date";
            label ahist_code="ahist_code: Last gemscript code before (excluding) cohort entry date";
            label ahistc_tot="ahistc_tot: HISTAMINE ANTAGONISTS_COMBINATIONS.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label ahistc_last="ahistc_last: Days between last date of prescription and (excluding) cohort entry date";
            label ahistc_first="ahistc_first: Days between first date of prescription and (excluding) cohort entry date";
            label ahistc_code="ahistc_code: Last gemscript code before (excluding) cohort entry date";
            label h2_tot="h2_tot: HISTAMIN-H2-RECEPTOR ANTAGONISTS.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label h2_last="h2_last: Days between last date of prescription and (excluding) cohort entry date";
            label h2_first="h2_first: Days between first date of prescription and (excluding) cohort entry date";
            label h2_code="h2_code: Last gemscript code before (excluding) cohort entry date";
            label ppi_tot="ppi_tot: PROTON PUMP INHIBITORS.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label ppi_last="ppi_last: Days between last date of prescription and (excluding) cohort entry date";
            label ppi_first="ppi_first: Days between first date of prescription and (excluding) cohort entry date";
            label ppi_code="ppi_code: Last gemscript code before (excluding) cohort entry date";
            label IBD_tot="IBD_tot: INFLAMMATION INHIBITORS INTESTINAL.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label IBD_last="IBD_last: Days between last date of prescription and (excluding) cohort entry date";
            label IBD_first="IBD_first: Days between first date of prescription and (excluding) cohort entry date";
            label IBD_code="IBD_code: Last gemscript code before (excluding) cohort entry date";
            label thyro_tot="thyro_tot: THYROID GLAND THERAPY.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label thyro_last="thyro_last: Days between last date of prescription and (excluding) cohort entry date";
            label thyro_first="thyro_first: Days between first date of prescription and (excluding) cohort entry date";
            label thyro_code="thyro_code: Last gemscript code before (excluding) cohort entry date";
            label sterint_tot="sterint_tot: CORTICOSTEROIDS INTESTINAL.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label sterint_last="sterint_last: Days between last date of prescription and (excluding) cohort entry date";
            label sterint_first="sterint_first: Days between first date of prescription and (excluding) cohort entry date";
            label sterint_code="sterint_code: Last gemscript code before (excluding) cohort entry date";
            label stersys_tot="stersys_tot: CORTICOSTEROIDS-SYSTEMIC.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label stersys_last="stersys_last: Days between last date of prescription and (excluding) cohort entry date";
            label stersys_first="stersys_first: Days between first date of prescription and (excluding) cohort entry date";
            label stersys_code="stersys_code: Last gemscript code before (excluding) cohort entry date";
            label stertop_tot="stertop_tot: CORTICOSTEROIDS-TOPICAL.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label stertop_last="stertop_last: Days between last date of prescription and (excluding) cohort entry date";
            label stertop_first="stertop_first: Days between first date of prescription and (excluding) cohort entry date";
            label stertop_code="stertop_code: Last gemscript code before (excluding) cohort entry date";
            label gesta_tot="gesta_tot: GESTAGENS.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label gesta_last="gesta_last: Days between last date of prescription and (excluding) cohort entry date";
            label gesta_first="gesta_first: Days between first date of prescription and (excluding) cohort entry date";
            label gesta_code="gesta_code: Last gemscript code before (excluding) cohort entry date";
            label pill_tot="pill_tot: HORMONAL CONTRACEPTION.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label pill_last="pill_last: Days between last date of prescription and (excluding) cohort entry date";
            label pill_first="pill_first: Days between first date of prescription and (excluding) cohort entry date";
            label pill_code="pill_code: Last gemscript code before (excluding) cohort entry date";
            label adem_tot="adem_tot: ANTIDEMENTIVA.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label adem_last="adem_last: Days between last date of prescription and (excluding) cohort entry date";
            label adem_first="adem_first: Days between first date of prescription and (excluding) cohort entry date";
            label adem_code="adem_code: Last gemscript code before (excluding) cohort entry date";
            label apsy_tot="apsy_tot: ANTIPSYCHOTIC DRUGS.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label apsy_last="apsy_last: Days between last date of prescription and (excluding) cohort entry date";
            label apsy_first="apsy_first: Days between first date of prescription and (excluding) cohort entry date";
            label apsy_code="apsy_code: Last gemscript code before (excluding) cohort entry date";
            label benzo_tot="benzo_tot: BENZODIAZEPINES.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label benzo_last="benzo_last: Days between last date of prescription and (excluding) cohort entry date";
            label benzo_first="benzo_first: Days between first date of prescription and (excluding) cohort entry date";
            label benzo_code="benzo_code: Last gemscript code before (excluding) cohort entry date";
            label hypno_tot="hypno_tot: HYPNOTICS.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label hypno_last="hypno_last: Days between last date of prescription and (excluding) cohort entry date";
            label hypno_first="hypno_first: Days between first date of prescription and (excluding) cohort entry date";
            label hypno_code="hypno_code: Last gemscript code before (excluding) cohort entry date";
            label ssri_tot="ssri_tot: SELECTIVE SEROTONIN REUPTAKE INHIBITORS.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label ssri_last="ssri_last: Days between last date of prescription and (excluding) cohort entry date";
            label ssri_first="ssri_first: Days between first date of prescription and (excluding) cohort entry date";
            label ssri_code="ssri_code: Last gemscript code before (excluding) cohort entry date";
            label li_tot="li_tot: LITHIUM.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label li_last="li_last: Days between last date of prescription and (excluding) cohort entry date";
            label li_first="li_first: Days between first date of prescription and (excluding) cohort entry date";
            label li_code="li_code: Last gemscript code before (excluding) cohort entry date";
            label mao_tot="mao_tot: MONOAMINOXIDASE A INHIBITORS.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label mao_last="mao_last: Days between last date of prescription and (excluding) cohort entry date";
            label mao_first="mao_first: Days between first date of prescription and (excluding) cohort entry date";
            label mao_code="mao_code: Last gemscript code before (excluding) cohort entry date";
            label oadep_tot="oadep_tot: ANTIDEPRESSIVA OTHER.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label oadep_last="oadep_last: Days between last date of prescription and (excluding) cohort entry date";
            label oadep_first="oadep_first: Days between first date of prescription and (excluding) cohort entry date";
            label oadep_code="oadep_code: Last gemscript code before (excluding) cohort entry date";
            label mnri_tot="mnri_tot: MONOAMIN REUPTAKE INHIBITORS.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label mnri_last="mnri_last: Days between last date of prescription and (excluding) cohort entry date";
            label mnri_first="mnri_first: Days between first date of prescription and (excluding) cohort entry date";
            label mnri_code="mnri_code: Last gemscript code before (excluding) cohort entry date";
            label adep_tot="adep_tot: ANTIDEPRESSANTS_ALL.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label adep_last="adep_last: Days between last date of prescription and (excluding) cohort entry date";
            label adep_first="adep_first: Days between first date of prescription and (excluding) cohort entry date";
            label adep_code="adep_code: Last gemscript code before (excluding) cohort entry date";
            label pheny_tot="pheny_tot: ANTICONVULSANTS PHENYTOIN.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label pheny_last="pheny_last: Days between last date of prescription and (excluding) cohort entry date";
            label pheny_first="pheny_first: Days between first date of prescription and (excluding) cohort entry date";
            label pheny_code="pheny_code: Last gemscript code before (excluding) cohort entry date";
            label barbi_tot="barbi_tot: ANTICONVULSANTS BARBITURATES.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label barbi_last="barbi_last: Days between last date of prescription and (excluding) cohort entry date";
            label barbi_first="barbi_first: Days between first date of prescription and (excluding) cohort entry date";
            label barbi_code="barbi_code: Last gemscript code before (excluding) cohort entry date";
            label succi_tot="succi_tot: ANTICONVULSANTS SUCCINIMID.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label succi_last="succi_last: Days between last date of prescription and (excluding) cohort entry date";
            label succi_first="succi_first: Days between first date of prescription and (excluding) cohort entry date";
            label succi_code="succi_code: Last gemscript code before (excluding) cohort entry date";
            label valpro_tot="valpro_tot: ANTICONVULSANTS VALPROATE.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label valpro_last="valpro_last: Days between last date of prescription and (excluding) cohort entry date";
            label valpro_first="valpro_first: Days between first date of prescription and (excluding) cohort entry date";
            label valpro_code="valpro_code: Last gemscript code before (excluding) cohort entry date";
            label carba_tot="carba_tot: ANTICONVULSANTS CARBAMAZEPINE.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label carba_last="carba_last: Days between last date of prescription and (excluding) cohort entry date";
            label carba_first="carba_first: Days between first date of prescription and (excluding) cohort entry date";
            label carba_code="carba_code: Last gemscript code before (excluding) cohort entry date";
            label oaconvu_tot="oaconvu_tot: ANTICONVULSANTS OTHERS.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label oaconvu_last="oaconvu_last: Days between last date of prescription and (excluding) cohort entry date";
            label oaconvu_first="oaconvu_first: Days between first date of prescription and (excluding) cohort entry date";
            label oaconvu_code="oaconvu_code: Last gemscript code before (excluding) cohort entry date";
            label aconvu_tot="aconvu_tot: ANTICONVULSANTS_ALL.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label aconvu_last="aconvu_last: Days between last date of prescription and (excluding) cohort entry date";
            label aconvu_first="aconvu_first: Days between first date of prescription and (excluding) cohort entry date";
            label aconvu_code="aconvu_code: Last gemscript code before (excluding) cohort entry date";
            label isupp_tot="isupp_tot: IMMUNOSUPPRESSIVES TOTAL.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label isupp_last="isupp_last: Days between last date of prescription and (excluding) cohort entry date";
            label isupp_first="isupp_first: Days between first date of prescription and (excluding) cohort entry date";
            label isupp_code="isupp_code: Last gemscript code before (excluding) cohort entry date";
            label dpp4i_tot="dpp4i_tot: ORAL ANTIDIABETICS_GLIPTINS (DPP4)_ALL_SCH.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label dpp4i_last="dpp4i_last: Days between last date of prescription and (excluding) cohort entry date";
            label dpp4i_first="dpp4i_first: Days between first date of prescription and (excluding) cohort entry date";
            label dpp4i_code="dpp4i_code: Last gemscript code before (excluding) cohort entry date";
            label sulfonyl_tot="sulfonyl_tot: ORAL ANTIDIABETICS_SULFONYLUREAS_STANDARD.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label sulfonyl_last="sulfonyl_last: Days between last date of prescription and (excluding) cohort entry date";
            label sulfonyl_first="sulfonyl_first: Days between first date of prescription and (excluding) cohort entry date";
            label sulfonyl_code="sulfonyl_code: Last gemscript code before (excluding) cohort entry date";
            label sglt2i_tot="sglt2i_tot: ORAL ANTIDIABETICS_SGLT2 INHIB_ALL_SCH.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label sglt2i_last="sglt2i_last: Days between last date of prescription and (excluding) cohort entry date";
            label sglt2i_first="sglt2i_first: Days between first date of prescription and (excluding) cohort entry date";
            label sglt2i_code="sglt2i_code: Last gemscript code before (excluding) cohort entry date";
            label TZD_tot="TZD_tot: ORAL ANTIDIABETICS_THIAZOLIDINEDIONES (PPAR)_SCH.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label TZD_last="TZD_last: Days between last date of prescription and (excluding) cohort entry date";
            label TZD_first="TZD_first: Days between first date of prescription and (excluding) cohort entry date";
            label TZD_code="TZD_code: Last gemscript code before (excluding) cohort entry date";
            label GLP1_tot="GLP1_tot: ORAL ANTIDIABETICS_GLP-1 (INCRETIN MIMETICS)_SCH.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label GLP1_last="GLP1_last: Days between last date of prescription and (excluding) cohort entry date";
            label GLP1_first="GLP1_first: Days between first date of prescription and (excluding) cohort entry date";
            label GLP1_code="GLP1_code: Last gemscript code before (excluding) cohort entry date";
            label metformin_tot="metformin_tot: ORAL ANTIDIABETICS_BIGUANIDES_METFORMIN_SPEZIFISCH.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label metformin_last="metformin_last: Days between last date of prescription and (excluding) cohort entry date";
            label metformin_first="metformin_first: Days between first date of prescription and (excluding) cohort entry date";
            label metformin_code="metformin_code: Last gemscript code before (excluding) cohort entry date";
            label sitagliptin_tot="sitagliptin_tot: SITAGLIPTIN.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label sitagliptin_last="sitagliptin_last: Days between last date of prescription and (excluding) cohort entry date";
            label sitagliptin_first="sitagliptin_first: Days between first date of prescription and (excluding) cohort entry date";
            label sitagliptin_code="sitagliptin_code: Last gemscript code before (excluding) cohort entry date";
            label vildagliptin_tot="vildagliptin_tot: VILDAGLIPTIN.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label vildagliptin_last="vildagliptin_last: Days between last date of prescription and (excluding) cohort entry date";
            label vildagliptin_first="vildagliptin_first: Days between first date of prescription and (excluding) cohort entry date";
            label vildagliptin_code="vildagliptin_code: Last gemscript code before (excluding) cohort entry date";
            label saxagliptin_tot="saxagliptin_tot: SAXAGLIPTIN.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label saxagliptin_last="saxagliptin_last: Days between last date of prescription and (excluding) cohort entry date";
            label saxagliptin_first="saxagliptin_first: Days between first date of prescription and (excluding) cohort entry date";
            label saxagliptin_code="saxagliptin_code: Last gemscript code before (excluding) cohort entry date";
            label linagliptin_tot="linagliptin_tot: LINAGLIPTIN.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label linagliptin_last="linagliptin_last: Days between last date of prescription and (excluding) cohort entry date";
            label linagliptin_first="linagliptin_first: Days between first date of prescription and (excluding) cohort entry date";
            label linagliptin_code="linagliptin_code: Last gemscript code before (excluding) cohort entry date";
            label alogliptin_tot="alogliptin_tot: ALOGLIPTIN.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label alogliptin_last="alogliptin_last: Days between last date of prescription and (excluding) cohort entry date";
            label alogliptin_first="alogliptin_first: Days between first date of prescription and (excluding) cohort entry date";
            label alogliptin_code="alogliptin_code: Last gemscript code before (excluding) cohort entry date";
            label ASA_tot="ASA_tot: AMINOSALICYLATES.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label ASA_last="ASA_last: Days between last date of prescription and (excluding) cohort entry date";
            label ASA_first="ASA_first: Days between first date of prescription and (excluding) cohort entry date";
            label ASA_code="ASA_code: Last gemscript code before (excluding) cohort entry date";
            label mesala_tot="mesala_tot: MESALAZINE.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label mesala_last="mesala_last: Days between last date of prescription and (excluding) cohort entry date";
            label mesala_first="mesala_first: Days between first date of prescription and (excluding) cohort entry date";
            label mesala_code="mesala_code: Last gemscript code before (excluding) cohort entry date";
            label sulfasala_tot="sulfasala_tot: SULFASALAZINE.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label sulfasala_last="sulfasala_last: Days between last date of prescription and (excluding) cohort entry date";
            label sulfasala_first="sulfasala_first: Days between first date of prescription and (excluding) cohort entry date";
            label sulfasala_code="sulfasala_code: Last gemscript code before (excluding) cohort entry date";
            label olsala_tot="olsala_tot: OLSALAZINE.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label olsala_last="olsala_last: Days between last date of prescription and (excluding) cohort entry date";
            label olsala_first="olsala_first: Days between first date of prescription and (excluding) cohort entry date";
            label olsala_code="olsala_code: Last gemscript code before (excluding) cohort entry date";
            label balsala_tot="balsala_tot: BALSALAZINE.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label balsala_last="balsala_last: Days between last date of prescription and (excluding) cohort entry date";
            label balsala_first="balsala_first: Days between first date of prescription and (excluding) cohort entry date";
            label balsala_code="balsala_code: Last gemscript code before (excluding) cohort entry date";
            label meglitinide_tot="meglitinide_tot: ORAL ANTIDIABETICS_GLINIDES_STANDARD.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label meglitinide_last="meglitinide_last: Days between last date of prescription and (excluding) cohort entry date";
            label meglitinide_first="meglitinide_first: Days between first date of prescription and (excluding) cohort entry date";
            label meglitinide_code="meglitinide_code: Last gemscript code before (excluding) cohort entry date";
            label HRTopp_tot="HRTopp_tot: HRT ESTROGEN OPPOSED.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label HRTopp_last="HRTopp_last: Days between last date of prescription and (excluding) cohort entry date";
            label HRTopp_first="HRTopp_first: Days between first date of prescription and (excluding) cohort entry date";
            label HRTopp_code="HRTopp_code: Last gemscript code before (excluding) cohort entry date";
            label HRToverall_tot="HRToverall_tot: HRT.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label HRToverall_last="HRToverall_last: Days between last date of prescription and (excluding) cohort entry date";
            label HRToverall_first="HRToverall_first: Days between first date of prescription and (excluding) cohort entry date";
            label HRToverall_code="HRToverall_code: Last gemscript code before (excluding) cohort entry date";
            label TNFai_tot="TNFai_tot: TNF ALPHA INHIBITORS.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label TNFai_last="TNFai_last: Days between last date of prescription and (excluding) cohort entry date";
            label TNFai_first="TNFai_first: Days between first date of prescription and (excluding) cohort entry date";
            label TNFai_code="TNFai_code: Last gemscript code before (excluding) cohort entry date";
            label budes_tot="budes_tot: BUDESONIDE.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label budes_last="budes_last: Days between last date of prescription and (excluding) cohort entry date";
            label budes_first="budes_first: Days between first date of prescription and (excluding) cohort entry date";
            label budes_code="budes_code: Last gemscript code before (excluding) cohort entry date";
            label Adcombo_tot="Adcombo_tot: ORAL ANTIDIABETICS_COMBINATIONS.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label Adcombo_last="Adcombo_last: Days between last date of prescription and (excluding) cohort entry date";
            label Adcombo_first="Adcombo_first: Days between first date of prescription and (excluding) cohort entry date";
            label Adcombo_code="Adcombo_code: Last gemscript code before (excluding) cohort entry date";
            label immureg_tot="immureg_tot: OTHER IMMUNOSUPPRESSIVES.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label immureg_last="immureg_last: Days between last date of prescription and (excluding) cohort entry date";
            label immureg_first="immureg_first: Days between first date of prescription and (excluding) cohort entry date";
            label immureg_code="immureg_code: Last gemscript code before (excluding) cohort entry date";
            label cyclosp_tot="cyclosp_tot: CYCLOSPORINE INTRAVENOUS.TXT ... Number of prescriptions prior (excluding) cohort entry date";
            label cyclosp_last="Days between last date of prescription and (excluding) cohort entry date";
            label cyclosp_first="Days between first date of prescription and (excluding) cohort entry date";
            label cyclosp_code="Last gemscript code before (excluding) cohort entry date";
            label timep="Timepoint (cohort entry date=0, starttime 1=1, starttime 2=2,…) {timep}";
            label tx_at_timep="Treatment at timepoint X (each available timepoint) {no comparator drug=0, sulfonylureas (SU)=1, SGLT2=2, thiazolidinediones (TZD)=3, SU+SGLT2=4, SU+TZD=5, TZD+SGLT2=6, SU+SGLT2+TZD=7}.";
            label start="Start time (start 0=cohort entry date, start 1=1, start 2 = 182 or time since the cohort entry date until the next treatment status change, start 3=start 2 +182 days or time since cohort entry until the next treatment status change,…) {start}";
            label stop="Stop time (Stop 0=1, stop 1=182 or time since cohort entry date until a change in treatment status,…) {stop}";
            label startstop="Time from start time to stop time {startstop}";
            label tx_status="Treatment status: 1=unchanged treatment, 2=drug class discontinuation, 3=switching, 4=adding";
            label exit_reason="Reason for exit {outcome of interest=1, end of follow-up=2, 180 days after treatment discontinuation=3, 180 days after switching or adding of drug class =4, death =5, database exit =6}";
/*            label EOL="End of line (eol)"*/
;

        RUN;


    %mend read_csv;

