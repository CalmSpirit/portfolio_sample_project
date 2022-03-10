package doc.controller;

import java.util.HashMap;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.ModelAndView;

import common.util.CommonUtil;
import doc.service.DocHelper;

@Controller
@RequestMapping("/doc")
public class DocController {

	/**
	 * @methodName : createDocMulti
	 * @author : hckim
	 * @date : 2021.09.09
	 * @return : ModelAndView
	 * @description : Doc 멀티등록 페이지
	 */
	@RequestMapping("/createDocMulti")
	public ModelAndView createDocMulti(@RequestParam Map<String, Object> reqMap) {

		ModelAndView model = new ModelAndView();
		model.setViewName("default:/doc/createDocMulti");

		return model;
	}

	/**
	 * @methodName : createDocMultiAction
	 * @author : hckim
	 * @date : 2021.09.09
	 * @return : ModelAndView
	 * @description :
	 */
	@ResponseBody
	@RequestMapping("/createDocMultiAction")
	public Map<String, Object> createDocMultiAction(HttpServletRequest request, HttpServletResponse response) {

		Map<String, Object> map = new HashMap<String, Object>();

		try {

			DocHelper.service.createDocMultiAction(request, response);

			map.put("result", true);
			map.put("msg", "등록이 완료되었습니다.");
			map.put("redirectUrl", CommonUtil.getURLString("/doc/searchDoc"));

		} catch (Exception e) {
			map.put("result", false);
			map.put("msg", "ERROR = " + e.getLocalizedMessage());
			e.printStackTrace();
		}

		return map;
	}
}
