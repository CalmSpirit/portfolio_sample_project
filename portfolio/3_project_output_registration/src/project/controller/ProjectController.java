package project.controller;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.ModelAndView;

import common.util.StringUtil;
import project.bean.GateOutputData;
import project.bean.ProjectData;
import project.service.ProjectHelper;

@Controller
@RequestMapping("/project")
public class ProjectController {
	
	
	/**
	 * @methodName : outputForGateInfo
	 * @author : hckim
	 * @date : 2021.10.25
	 * @return : ModelAndView
	 * @description : 상세정보 -> 게이트 별 산출물 include
	 */
	@RequestMapping("/include_outputForGateInfo")
	public ModelAndView outputForGateInfo(@RequestParam Map<String, Object> reqMap) {
		ModelAndView model = new ModelAndView();

		String oid = StringUtil.checkNull((String) reqMap.get("oid"));
		String autoGridHeight = StringUtil.checkReplaceStr((String) reqMap.get("autoGridHeight"), "false");
		String gridHeight = StringUtil.checkReplaceStr((String) reqMap.get("gridHeight"), "200");
		
		ProjectData projectData = new ProjectData(oid);

		model.addObject("oid", oid);
		model.addObject("project", projectData);
		model.addObject("autoGridHeight", autoGridHeight);
		model.addObject("gridHeight", gridHeight);

		model.setViewName("include:/project/include/outputForGateInfo");

		return model;
	}
	
	
	/**
	 * @methodName : getGateOutputList
	 * @author : hckim
	 * @date : 2021.11.08
	 * @return : Map<String,Object>
	 * @description : 
	 */
	@ResponseBody
	@RequestMapping("/getGateOutputList")
	public Map<String, Object> getGateOutputList(@RequestBody Map<String, Object> reqMap) {

		Map<String, Object> map = new HashMap<String, Object>();

		try {

			List<GateOutputData> list = ProjectHelper.manager.searchGateOutputList(reqMap); 
			
			map.put("list", list);
			map.put("result", true);
		} catch (Exception e) {
			map.put("result", false);
			map.put("msg", "ERROR = " + e.getLocalizedMessage());
		}

		return map;
	}

	
	/**
	 * @methodName : createOutputMultiPopup
	 * @author : hckim
	 * @date : 2021.10.29
	 * @return : ModelAndView
	 * @description : 
	 */
	@RequestMapping("/createOutputMultiPopup")
	public ModelAndView createOutputMultiPopup(@RequestParam Map<String, Object> reqMap) {

		ModelAndView model = new ModelAndView();

		try {
			model.setViewName("popup:/project/createOutputMultiPopup");
		} catch (Exception e) {
			e.printStackTrace();
		}

		return model;
	}

	/**
	 * @methodName : createOutputMultiAction
	 * @author : hckim
	 * @date : 2021.11.19
	 * @return : Map<String,Object>
	 * @description : 
	 */
	@ResponseBody
	@RequestMapping("/createOutputMultiAction")
	public Map<String, Object> createOutputMultiAction(HttpServletRequest request, HttpServletResponse response) {

		Map<String, Object> map = new HashMap<String, Object>();

		try {

			ProjectHelper.service.createOutputDocumentAction(request, response);

			map.put("result", true);
			map.put("msg", "등록이 완료되었습니다.");

		} catch (Exception e) {
			map.put("result", false);
			map.put("msg", "ERROR = " + e.getLocalizedMessage());
			e.printStackTrace();
		}

		return map;
	}
	
}
