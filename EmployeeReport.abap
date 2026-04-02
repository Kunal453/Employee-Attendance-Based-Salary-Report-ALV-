*&---------------------------------------------------------------------*
*& Report Y180R020_SALARY_PROCESSING_ALV
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT y180r020_salary_processing_alv.

TABLES: y180m_empmst, y180d_saltrn, y180d_mtdatt.


SELECTION-SCREEN BEGIN OF BLOCK blk01 WITH FRAME TITLE TEXT-001.

  SELECT-OPTIONS: s_empno FOR y180m_empmst-empno.
  PARAMETERS: P_month TYPE y180d_mtdatt-yymm.

SELECTION-SCREEN END OF BLOCK blk01.

SELECTION-SCREEN BEGIN OF BLOCK blk02 WITH FRAME TITLE TEXT-002.

  PARAMETERS: pr_attn RADIOBUTTON GROUP grp1, "Radio button for Attendance calculation
              pr_sal  RADIOBUTTON GROUP grp1.  "Radio button for salry calculation

SELECTION-SCREEN END OF BLOCK blk02.


DATA: gv_empno      TYPE y180m_empmst-empno,
      gs_mtdatt     TYPE y180s_mtdatt,
      gs_mtdatt_res TYPE y180s_mtdatt,
      gs_saltrn_res TYPE y180s_saltrn,
      gs_saltrn     TYPE y180s_saltrn,
      gv_pos        TYPE i,
      gs_output     TYPE y180s_empmst,
      gs_empsal     TYPE y180s_empmst,
      gt_fieldcat   TYPE slis_t_fieldcat_alv,
      gt_fieldcat_1 TYPE slis_t_fieldcat_alv.

DATA: gt_mtdatt     TYPE y180t_mtdatt,
      gt_saltrn     TYPE y180t_saltrn,
      gt_mtdatt_res TYPE y180t_mtdatt,
      gt_saltrn_res TYPE y180t_saltrn,
      gt_output     TYPE y180t_empsal,
      gt_empsal     TYPE y180t_empsal.

DATA: gv_user_command TYPE slis_formname VALUE 'USER_COMMAND'. "This is use for double click.



AT SELECTION-SCREEN.
  IF s_empno-low IS INITIAL OR s_empno-high IS INITIAL.
    MESSAGE ID 'Y180' TYPE 'E' NUMBER '014'.
  ENDIF.
  IF p_month IS INITIAL.
    MESSAGE ID 'Y180' TYPE 'E' NUMBER '015'.
  ENDIF.
  IF s_empno-high < s_empno-low.
    MESSAGE ID 'Y180' TYPE 'E' NUMBER '016'.
  ENDIF.

START-OF-SELECTION.
  PERFORM get_data_att USING gs_mtdatt_res. "done
  PERFORM process_data_att.   "done
  IF pr_sal = 'X'.
    PERFORM get_data_sal USING gs_saltrn_res.  " done
    PERFORM process_data_sal. "done
  ENDIF.

END-OF-SELECTION.

  IF pr_attn = 'X'.
    PERFORM fill_field_catlog2att. "done
    PERFORM call_alv_att.    "done
  ENDIF.

  IF pr_sal = 'X'.
    PERFORM fill_field_catlog_sal. "done
    PERFORM call_alv_sal.  "done
  ENDIF.

*&---------------------------------------------------------------------*
*& Form get_data_att
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GS_MTDATT_RES
*&---------------------------------------------------------------------*
FORM get_data_att  USING    us_mtdatt_res TYPE y180s_mtdatt.
  SELECT
    empno
    yymm
    days_present
    FROM y180d_mtdatt
    INTO TABLE gt_mtdatt
    WHERE empno IN s_empno
   AND yymm = p_month.
ENDFORM.


*&---------------------------------------------------------------------*
*& Form process_data_att
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM process_data_att .
  DATA: lv_curr_mm            TYPE n LENGTH 2,
        lv_year               TYPE n LENGTH 4,
        lv_low_att            TYPE char20,
        lv_high_att           TYPE char20,
        lv_att_percent        TYPE p DECIMALS 2,
        lv_bef_empno          TYPE Y180m_empmst-empno, "Before
        lv_aft_empno          TYPE Y180m_empmst-empno, "after
        lv_bas                TYPE Y180m_salmst-salary,
        lv_subtotal           TYPE Y180m_salmst-salary,
        lv_total              TYPE Y180m_salmst-salary,
        lv_pf                 TYPE Y180m_salmst-salary,
        lv_sal_without_dedutn TYPE Y180m_salmst-salary,  " salary without deduction.
        lv_subtotal_wo_bas    TYPE Y180m_salmst-salary,
        lv_attend             TYPE y180days_present,
        lv_total_days         TYPE y180days_present,
        lv_count_records      TYPE i,
        ls_empsal             TYPE y180s_empsal.


  lv_low_att = 'Low Attendance'.
  lv_high_att = 'Excellent Attendance'.

  LOOP AT gt_mtdatt INTO gs_mtdatt.
    lv_curr_mm = gs_mtdatt-yymm+4(2).
    lv_year = gs_mtdatt-yymm+0(4).

    CASE lv_curr_mm.
      WHEN 01 OR 03 OR 05 OR 07 OR 08 OR 10 OR 12.
        gs_mtdatt-total_days = 31.
      WHEN 04 OR 06 OR 09 OR 11.
        gs_mtdatt-total_days = 30.
      WHEN 02.
        IF ( lv_year MOD 4  = 0 ) AND ( lv_year MOD 100 <> 0 OR lv_year MOD 400 = 0 ).
          gs_mtdatt-total_days = 29.
        ELSE.
          gs_mtdatt-total_days = 28.
        ENDIF.
      WHEN OTHERS.
    ENDCASE.

    IF gs_mtdatt-total_days > 0.
      lv_att_percent = ( gs_mtdatt-days_present * 100 )
                       / gs_mtdatt-total_days.
    ENDIF.


    "lv_att_percent = ( gs_mtdatt-days_present * 100 ) / gs_mtdatt-total_days.
    IF lv_att_percent < 50.
      gs_mtdatt-remarks = 'Low Attendance'.
    ELSE.
      gs_mtdatt-remarks = 'Excellent Attendance'.
    ENDIF.
    APPEND gs_mtdatt TO gt_mtdatt_res.
    CLEAR gs_mtdatt.
  ENDLOOP.
ENDFORM.



*&---------------------------------------------------------------------*
*& Form get_data_sal
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GS_SALTRN_RES
*&---------------------------------------------------------------------*
FORM get_data_sal  USING    us_saltrn_res TYPE y180s_saltrn.
  SELECT
    a~empno
    a~yymm
    a~salhd
    a~salary
    a~waers
      b~saltp
      INTO TABLE gt_saltrn
      FROM y180d_saltrn AS a
      INNER JOIN y180c_salhd AS b
      ON a~salhd = b~salhd
      WHERE empno IN s_empno AND yymm = p_month.
ENDFORM.


*&---------------------------------------------------------------------*
*& Form process_data_sal
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM process_data_sal .

  SORT gt_saltrn BY empno.

  DATA: lv_bas                TYPE y180m_salmst-salary,
        lv_subtotal           TYPE y180m_salmst-salary,
        lv_total              TYPE y180m_salmst-salary,
        lv_pf                 TYPE y180m_salmst-salary,
        lv_sal_without_dedutn TYPE y180m_salmst-salary,
        lv_attend             TYPE y180days_present,
        lv_total_days         TYPE y180days_present.

  LOOP AT gt_saltrn INTO gs_saltrn.

    AT NEW empno.
      CLEAR: lv_bas, lv_subtotal, lv_total, lv_pf.
    ENDAT.

    "EARNINGS
    IF gs_saltrn-salty = 'E'.
      IF gs_saltrn-salhd = 'BAS'.
        lv_bas = gs_saltrn-salary.
        READ TABLE gt_mtdatt_res INTO gs_mtdatt
             WITH KEY empno = gs_saltrn-empno
                      yymm  = p_month.

        IF sy-subrc = 0 AND gs_mtdatt-total_days > 0.
          lv_attend     = gs_mtdatt-days_present.
          lv_total_days = gs_mtdatt-total_days.
          lv_sal_without_dedutn = gs_saltrn-salary * lv_attend / lv_total_days.
        ELSE.
          lv_sal_without_dedutn = gs_saltrn-salary.
        ENDIF.

        gs_saltrn_res-salary = lv_sal_without_dedutn.
        lv_total = lv_total + lv_sal_without_dedutn.
      ELSE.
        gs_saltrn_res-salary = gs_saltrn-salary.
        lv_total = lv_total + gs_saltrn-salary.
      ENDIF.

      lv_subtotal = lv_subtotal + gs_saltrn_res-salary.
      gs_saltrn_res-salty = 'EARNING'.

      "DEDUCTIONS
    ELSEIF gs_saltrn-salty = 'D'.
      lv_subtotal = lv_subtotal - gs_saltrn-salary.
      lv_total    = lv_total    - gs_saltrn-salary.

      gs_saltrn_res-salary = gs_saltrn-salary.
      gs_saltrn_res-salty  = 'DEDUCTION'.
    ENDIF.

    "APPEND CURRENT ROW
    gs_saltrn_res-empno = gs_saltrn-empno.
    gs_saltrn_res-salhd = gs_saltrn-salhd.
    gs_saltrn_res-waers = gs_saltrn-waers.

    APPEND gs_saltrn_res TO gt_saltrn_res.
    CLEAR gs_saltrn_res.

    "EMPLOYEE BREAK
    AT END OF empno.
      "PF calaculation.
      lv_pf = lv_bas * 12 / 100.
      "PF
      gs_saltrn_res-empno  = gs_saltrn-empno.
      gs_saltrn_res-salhd  = 'PF'.
      gs_saltrn_res-salary = lv_pf.
      gs_saltrn_res-waers  = 'INR'.
      gs_saltrn_res-salty  = 'DEDUCTION'.
      APPEND gs_saltrn_res TO gt_saltrn_res.

      "SUBTOTAL
      gs_saltrn_res-salhd  = 'SUB-TOTAL'.
      gs_saltrn_res-salary = lv_subtotal.
      gs_saltrn_res-salty  = 'EARNING'.
      APPEND gs_saltrn_res TO gt_saltrn_res.

      "TOTAL
      gs_saltrn_res-salhd  = 'TOTAL'.
      gs_saltrn_res-salary = lv_total - lv_pf.
      gs_saltrn_res-salty  = 'EARNING'.
      APPEND gs_saltrn_res TO gt_saltrn_res.

      CLEAR gs_saltrn_res.

    ENDAT.

  ENDLOOP.

ENDFORM.



*&---------------------------------------------------------------------*
*& Form fill_field_catlog2att
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM fill_field_catlog2att .
  PERFORM fill_catalog USING 'EMPNO'        'EMPNO'         'Y180D_MTDATT'  'Employee No.'    ''  ''   'X'.
  PERFORM fill_catalog USING 'YYMM'         'YYMM'          'Y180D_MTDATT'  'MONTH'           ''  ''   ''.
  PERFORM fill_catalog USING 'DAYS_PRESENT' 'DAYS_PRESENT'  'Y180D_MTDATT'  'DAYS PRESENT'    ''  ''   ''.
  PERFORM fill_catalog USING 'TOTAL_DAYS'   'TOTAL_DAYS'    'Y180D_MTDATT'  'TOTAL DAYS'      ''  ''   ''.
  PERFORM fill_catalog USING 'REMARKS'      'REMARKS'       ''              'REMARKS'         ''  ''   ''.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form call_alv_att
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM call_alv_att .
  IF pr_attn = 'X'.
    CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
      EXPORTING
        i_callback_program      = sy-repid
        i_callback_user_command = 'USER_COMMAND'
        i_callback_top_of_page  = 'TOP_OF_PAGE_1'
        it_fieldcat             = gt_fieldcat
        i_save                  = 'A'
      TABLES
        t_outtab                = gt_mtdatt_res.

    CLEAR gt_mtdatt_res.
    CLEAR gt_fieldcat.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form fill_field_catlog_sal
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM fill_field_catlog_sal .
  PERFORM fill_catalog USING 'EMPNO'  'EMPNO'   'Y180D_SALTRN'     'Employee No.'    '' ''  'X'.
  PERFORM fill_catalog USING 'SALHD'  'SALHD'   'Y180D_SALTRN'     'SALARY HEAD'     '' ''  ''.
  PERFORM fill_catalog USING 'SALARY' 'SALARY'  'Y180D_SALTRN'     'SALARY'          'WAERS' ''  ''.
  PERFORM fill_catalog USING 'WAERS'  'WAERS'   'Y180D_SALTRN'     'CURRENCY'        '' ''  ''.
  PERFORM fill_catalog USING 'SALTY'  'SALTY'   ''                 'SALARY TYPE'     '' ''  ''.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form cal_alv_sal
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM call_alv_sal.
  IF pr_sal = 'X'.
    CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
      EXPORTING
        i_callback_program      = sy-repid
        i_callback_user_command = 'USER_COMMAND'
        i_callback_top_of_page  = 'TOP_OF_PAGE_2'
        it_fieldcat             = gt_fieldcat
        i_save                  = 'A'
      TABLES
        t_outtab                = gt_saltrn_res.
    CLEAR gt_saltrn_res.
    CLEAR gt_fieldcat.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form fill_catalog
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_
*&      --> P_
*&      --> P_
*&      --> P_
*&      --> P_
*&      --> P_
*&      --> P_
*&---------------------------------------------------------------------*
FORM fill_catalog  USING    uv_itab_field_name
                         uv_ref_field_name
                         uv_ref_field_table
                         uv_short_text1
                         uv_currency_fieldname
                         uv_quantity_fieldname
                         uv_key_field_flag.
  DATA: ls_fieldcat TYPE slis_fieldcat_alv.


  CLEAR ls_fieldcat.
  gv_pos = gv_pos + 1.

  ls_fieldcat-col_pos       = gv_pos.
  ls_fieldcat-fieldname     = uv_itab_field_name.
  ls_fieldcat-ref_fieldname = uv_ref_field_name.
  ls_fieldcat-ref_tabname   = uv_ref_field_table.
  ls_fieldcat-seltext_s     = uv_short_text1.
  ls_fieldcat-seltext_m     = uv_short_text1.
  ls_fieldcat-seltext_l     = uv_short_text1.
  ls_fieldcat-reptext_ddic  = uv_short_text1.
  ls_fieldcat-key           = uv_key_field_flag.
  ls_fieldcat-cfieldname    = uv_currency_fieldname.
  ls_fieldcat-qfieldname    = uv_quantity_fieldname.

  APPEND ls_fieldcat TO gt_fieldcat.
ENDFORM.

" User command for double click

FORM user_command USING uv_ucomm TYPE sy-ucomm
      us_selfield TYPE slis_selfield.

  CASE uv_ucomm.
    WHEN '&IC1'.
      CLEAR gs_saltrn_res.
      IF pr_sal = 'X'.
        IF us_selfield-fieldname = 'EMPNO'.
          READ TABLE gt_saltrn_res INTO gs_saltrn_res INDEX us_selfield-tabindex.
          PERFORM get_data_emp2 USING gs_saltrn_res.
          PERFORM process_data_emp.
          PERFORM fill_field_catalog_empsal.
          PERFORM call_alv_empsal.
          PERFORM top_of_page_2.
        ENDIF.
      ELSEIF pr_attn = 'X'.
        CLEAR gs_mtdatt_res.
        IF us_selfield-fieldname = 'EMPNO'..
          READ TABLE gt_mtdatt_res INTO gs_mtdatt_res INDEX us_selfield-tabindex.
          PERFORM get_data_emp USING gs_mtdatt_res.
          PERFORM process_data_emp.
          PERFORM fill_field_catalog_empsal.
          PERFORM call_alv_empsal.
          PERFORM top_of_page_1.
        ENDIF.
      ENDIF.

  ENDCASE.

ENDFORM.





*&---------------------------------------------------------------------*
*& Form top-of-page-2
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM top_of_page_2.

  DATA: lt_header TYPE slis_t_listheader,
        ls_header TYPE slis_listheader.

  CLEAR ls_header.
  ls_header-typ = 'H'.
  ls_header-info = 'Salary Details of Employee.....!'.
  APPEND ls_header TO lt_header.
  CLEAR ls_header.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = lt_header.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form top-of-page-1
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM top_of_page_1.
  DATA: lt_header TYPE slis_t_listheader,
        ls_header TYPE slis_listheader.

  CLEAR ls_header.
  ls_header-typ = 'H'.
  ls_header-info = 'Attendance Details of Employee.....!'.
  APPEND ls_header TO lt_header.
  CLEAR ls_header.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = lt_header.
ENDFORM.


*&---------------------------------------------------------------------*
*& Form get_data_emp
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GS_MTDATT_RES
*&---------------------------------------------------------------------*
FORM get_data_emp  USING    p_gs_mtdatt_res TYPE y180s_mtdatt.
  SELECT
     a~empno
      a~empnm
      a~birthdt
      a~joindt
      a~gender
      a~phone_no
      a~email_id
      a~deptcd
      a~wlcd
      a~designation
      a~bankac
      a~banknm
      b~salary
    INTO TABLE gt_empsal
    FROM y180m_empmst AS a
    INNER JOIN y180m_salmst AS b
    ON a~empno = b~empno
    WHERE a~empno = p_gs_mtdatt_res-empno.
ENDFORM.



*&---------------------------------------------------------------------*
*& Form get_data_emp2
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GS_SALTRN_RES
*&---------------------------------------------------------------------*
FORM get_data_emp2  USING us_saltrn_res TYPE y180s_saltrn.
  SELECT
    a~empno
    a~empnm
    a~birthdt
    a~joindt
    a~gender
    a~phone_no
    a~email_id
    a~deptcd
    a~wlcd
    a~designation
    a~bankac
    a~banknm
    b~salary
    INTO  TABLE  gt_empsal
    FROM y180m_empmst AS a
    INNER JOIN y180m_salmst AS b
    ON a~empno = b~empno
    WHERE a~empno = us_saltrn_res-empno.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form process_data_emp
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM process_data_emp .
  DATA: ls_empsal TYPE y180s_empsal.

  LOOP AT gt_empsal INTO ls_empsal.
    COLLECT ls_empsal INTO gt_output.
  ENDLOOP.
ENDFORM.



*&---------------------------------------------------------------------*
*& Form fill_field_catalog_empsal
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM fill_field_catalog_empsal .
  PERFORM fill_catalog_emp USING 'EMPNO'       'EMPNO'        'Y180M_EMPMST'  'Employee Number'    '' ''  'X'.
  PERFORM fill_catalog_emp USING 'EMPNM'       'EMPNM'        'Y180M_EMPMST'  'Employee Name'      '' ''  ''.
  PERFORM fill_catalog_emp USING 'BIRTHDT'     'BIRTHDT'      'Y180M_EMPMST'  'Birth Date'         '' ''  ''.
  PERFORM fill_catalog_emp USING 'JOININGDT'   'JOININGDT'    'Y180M_EMPMST'  'Joining Date'       '' ''  ''.
  PERFORM fill_catalog_emp USING 'GENDER'      'GENDER'       'Y180M_EMPMST'  'Gender'             '' ''  ''.
  PERFORM fill_catalog_emp USING 'PHONE_NO'    'PHONE_NO'     'Y180M_EMPMST'  'Phone No.'          '' ''  ''.
  PERFORM fill_catalog_emp USING 'EMAIL_ID'    'EMAIL_ID'     'Y180M_EMPMST'  'Email id'           '' ''  ''.
  PERFORM fill_catalog_emp USING 'DEPTCD'      'DEPTCD'       'Y180M_EMPMST'  'Depatment Code'     '' ''  ''.
  PERFORM fill_catalog_emp USING 'WLCD'        'WLCD'         'Y180M_EMPMST'  'Work Location Code' '' ''  ''.
  PERFORM fill_catalog_emp USING 'DESIGNATION' 'DESIGNATION'  'Y180M_EMPMST'  'Designation'        '' ''  ''.
  PERFORM fill_catalog_emp USING 'BANKAC'      'BANKAC'       'Y180M_EMPMST'  'Bank Acc No.'       '' ''  ''.
  PERFORM fill_catalog_emp USING 'BANKNM'      'BANKNM'       'Y180M_EMPMST'  'Bank Name'          '' ''  ''.
  PERFORM fill_catalog_emp USING 'SALARY'      'SALARY'       'Y180M_EMPMST'  'Salary'             'WAERS' ''  ''.

ENDFORM.


*&---------------------------------------------------------------------*
*& Form fill_catalog_emp
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_
*&      --> P_
*&      --> P_
*&      --> P_
*&      --> P_
*&      --> P_
*&      --> P_
*&---------------------------------------------------------------------*
FORM fill_catalog_emp  USING   uv_itab_field_name
                         uv_ref_field_name
                         uv_ref_field_table
                         uv_short_text1
                         uv_currency_fieldname
                         uv_quantity_fieldname
                         uv_key_field_flag.
  DATA: ls_fieldcat TYPE slis_fieldcat_alv.
  CLEAR ls_fieldcat.
  gv_pos = gv_pos + 1.
  ls_fieldcat-col_pos       = gv_pos.
  ls_fieldcat-fieldname     = uv_itab_field_name.
  ls_fieldcat-ref_fieldname = uv_ref_field_name.
  ls_fieldcat-ref_tabname   = uv_ref_field_table.
  ls_fieldcat-seltext_s     = uv_short_text1.
  ls_fieldcat-seltext_m     = uv_short_text1.
  ls_fieldcat-seltext_l     = uv_short_text1.
  ls_fieldcat-reptext_ddic  = uv_short_text1.
  ls_fieldcat-key           = uv_key_field_flag.
  ls_fieldcat-cfieldname    = uv_currency_fieldname.
  ls_fieldcat-qfieldname    = uv_quantity_fieldname.
  APPEND ls_fieldcat TO  gt_fieldcat_1.
  CLEAR ls_fieldcat.


ENDFORM.

*&---------------------------------------------------------------------*
*& Form call_alv_empsal
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM call_alv_empsal .
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program = 'sy-repid'
      it_fieldcat        = gt_fieldcat_1
      i_save             = 'A'
    TABLES
      t_outtab           = gt_output.

  CLEAR: gt_output, gt_fieldcat_1.

ENDFORM.
