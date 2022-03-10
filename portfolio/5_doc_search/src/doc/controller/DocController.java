package doc.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.ModelAndView;

import approval.service.ApprovalHelper;
import common.util.CommonUtil;
import common.util.StringUtil;
import doc.beans.DocData;
import doc.service.DocHelper;


@Controller
@RequestMapping("/doc")
public class DocController {

	@RequestMapping("/searchDoc")
	public ModelAndView searchDoc(@RequestParam Map<String, Object> reqMap) {

		ModelAndView model = new ModelAndView();

		model.setViewName("default:/doc/searchDoc");

		return model;
	}

	@ResponseBody
	@RequestMapping("/searchDocScrollAction")
	public Map<String, Object> searchDocScrollAction(@RequestBody Map<String, Object> reqMap) {
		Map<String, Object> map = new HashMap<String, Object>();

		try {

			map = DocHelper.manager.getDocScrollList(reqMap);
			map.put("result", true);

		} catch (Exception e) {
			e.printStackTrace();
			map.put("result", false);
			map.put("msg", "ERROR = " + e.getLocalizedMessage());
		}

		return map;
	}

	@RequestMapping("/viewDoc")
	public ModelAndView viewDoc(@RequestParam Map<String, Object> reqMap) {

		ModelAndView model = new ModelAndView();

		try {
			
			String oid = StringUtil.checkNull((String) reqMap.get("oid"));

			WTDocument doc = (WTDocument) CommonUtil.getObject(oid);
			
			//수신자 해당 문서 OPEN 수신 처리
			ApprovalHelper.service.updaeRecive(doc);

			DocData docData = new DocData(doc, true);

			model.addObject("doc", docData);

			model.setViewName("popup:/doc/viewDoc");
		} catch (Exception e) {
			e.printStackTrace();
		}

		return model;
	}

	@RequestMapping("/include_detailDoc")
	public ModelAndView detailDoc(@RequestParam Map<String, Object> reqMap) {

		ModelAndView model = new ModelAndView();

		try {
			String oid = StringUtil.checkNull((String) reqMap.get("oid"));

			WTDocument doc = (WTDocument) CommonUtil.getObject(oid);

			DocData docData = new DocData(doc, true);

			model.addObject("doc", docData);

			model.setViewName("include:/doc/include/detailDoc");
		} catch (Exception e) {
			e.printStackTrace();
		}

		return model;
	}
}
