<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!-- 각 화면 개발시 Tag 복사해서 붙여넣고 사용할것 -->    
<%@ taglib prefix="c"		uri="http://java.sun.com/jsp/jstl/core"			%>
<%@ taglib prefix="tl" 	uri="/WEB-INF/tlds/tl-functions.tld"%>
<script type="text/javascript">
$(document).ready(function(){
	
	loadIncludePage();
	
	getRoleList();
	
});

//추가한 관련 문서
var addedRefDocList = [];

//추가한 관련 문서 파일
var addedRefDocFiles = {};

//추가한 관련 품목
var addedRelPartList = [];

//연동된 게이트
var addedGate = [];

//정의된 산출물
var addedOutput = [];

//구성원
var addedMemberList = [];


function loadIncludePage(tab) {
	
	if(tab == null) {
		tab = $(".tap>ul>li:first");
	}
	
	$(".tap ul li").removeClass("on");
	$(tab).addClass("on");
	
	var url = $(tab).data("url");
	
	var param = new Object();
	
	param["code"] = "ROOT";
	
	$("#includePage").load(url, param);
}

function getFormValue(inputName){
	
	return $("#projectForm")[0][inputName].value;
}


function getRoleList(){
	
	var param = new Object();
	param.codeType = "PROJECTROLE";
	param.disabledCheck = true;
	
	var roleNumberCode = getNumberCodeDataList(null, param, null, null, null);
	
	var roleArray = [];
	
	Array.prototype.forEach.call(roleNumberCode, function(code, idx){
		var role = new Object();
		role.roleName = code.name;
		role.roleCode = code.code;
		role.roleDescription = code.description;
		role.roleOid = code.oid;
		role.peopleOid = "";
		
		roleArray.push(role);
	});
	
	addedMemberList = roleArray;
}



function createProject_validate(){
	
	var validate = false;
	
	//기본 정보
	var name = getHiddenTag("projectName").val();
	if(!name.length > 0){
		alert("프로젝트 명은 필수 항목입니다.");
		return false;
	}
	
	var productGubun = getHiddenTag("productGubun").val();
	if(!productGubun.length > 0){
		alert("프로젝트 유형을 선택해주세요.");
		return false;
	}
	
	var existPM = false;
	for(var i = 0; i<addedMemberList.length; i++){
		var roleMember = addedMemberList[i];
		
		if(roleMember.roleCode == "PM10" || roleMember.roleCode == "PM20"){
			if(roleMember.peopleOid != null && roleMember.peopleOid.length > 0){
				existPM = true;
				break;
			}
		}
	}
	if(!existPM){
		alert("프로젝트의 책임자 또는 관리자를 지정해주십시오.");
		return false;
	}
	
	
	//참조 문서
	if(!validate_refDoc(addedRefDocList)){
		return false;
	}; 
	
	return true;
}

function save(){
	
	if(!createProject_validate()){
		return;
	}
	
	//금액 관련 쉼표 제거
	Array.prototype.forEach.call($("input[type=hidden][class=moneyExpression]"), function(element, idx){
		element.value = moneyTokenEraser(element.value);
	});
	
	var form = new FormData($("#projectForm")[0]);
	
	//참조 문서
	form.append("refdoc_totalSize", addedRefDocList.length);
	Array.prototype.forEach.call(addedRefDocList, function(refDoc, idx){
		form.append("refdoc_target_row_id", refDoc.targetRowId);
		form.append("refdoc_codetype", refDoc.docCodeType);
		form.append("refdoc_attribute", refDoc.docAttribute);
		form.append("refdoc_docName", refDoc.name);
		form.append("refdoc_attchment", addedRefDocFiles[refDoc.selfRowId].file);
		form.append("refdoc_description", refDoc.description);
	});
	
	//관련 부품
	Array.prototype.forEach.call(addedRelPartList, function(data, idx){
		form.append("add_part_oid", data.oid);
	});
	
	//Gate(Task)
	form.append("issue_totalSize", addedGate.length);
	Array.prototype.forEach.call(addedGate, function(gateInfo, idx){
		
		var gateName = gateInfo.gateName == null ? "" : gateInfo.gateName; 
		form.append("issue_gate_code", gateName);
		form.append("issue_id", gateInfo.jiraIssueId);
		form.append("issue_epic", gateInfo.jiraEpicName);//TASK 명
		form.append("issue_gate_description", gateInfo.gateDescription);//Gate 설명
	});
	
	form.append("output_totalSize", addedOutput.length);
	form.append("requestModule", "PROJECT");
	Array.prototype.forEach.call(addedOutput, function(output, idx){
		
		form.append("output_name", output.name);
		form.append("output_description", output.description);
		form.append("output_approve", output.approve);
		form.append("output_essential", output.essential);
		form.append("output_linkGate", output.linkGateOid);
		form.append("output_codetype", output.linkDocCodeTypeOid);
		form.append("output_attribute", output.linkDocAttributeOid);
	});
	//return;
	
	//구성원
	form.append("member_totalSize", addedMemberList.length);
	Array.prototype.forEach.call(addedMemberList, function(memberInfo, idx){
		
		var userReference = memberInfo.userReference == null ? "" : memberInfo.userReference;
		
		form.append("member_peopleOid", memberInfo.peopleOid);
		form.append("member_roleCode", memberInfo.roleCode);
		form.append("member_userReference", userReference);
		
	});
	
	var url = getURLString("/project/createProjectAction");
	callFormAjax(url, form, null, true);
}

//사용자가 입력한 값을 페이지가 기억함
function pageCaching(){
	
	//프로젝트 정보
	//프로젝트 이름
	if(getInputTag("projectName").length > 0){
		getHiddenTag("projectName").val(getInputTag("projectName").val());
	}
	
	//JiraID는 select2 변경 시 동작
	
	//프로젝트 유형
	if($("select[id=productGubun]").length > 0){
		
		if(getHiddenTag("productGubun").val() != $("select[id=productGubun]").val()){
			addedGate = [];
			addedOutput = [];
		}
		
		getHiddenTag("productGubun").val($("select[id=productGubun]").val());
	}
	
	//개발제품 명
	if(getInputTag("productType").length > 0){
		getHiddenTag("productType").val(getInputTag("productType").val());
	}
	
	//계획 시작일
	if(getInputTag("projectPlanStartDate").length > 0){
		getHiddenTag("projectPlanStartDate").val(getInputTag("projectPlanStartDate").val());
	}
	
	//계획 종료일
	if(getInputTag("projectPlanEndDate").length > 0){
		getHiddenTag("projectPlanEndDate").val(getInputTag("projectPlanEndDate").val());
	}
	
	//설명
	//editorCaching 함수 참고
	
	//MM
	if(getInputTag("expenseMM").length > 0){
		getHiddenTag("expenseMM").val(getInputTag("expenseMM").val());
	}
	
	//환종
	if($("select[id=expenseCurrency]").length > 0){
		getHiddenTag("expenseCurrency").val($("select[id=expenseCurrency]").val());
	}
	
	//MC
	if(getInputTag("expenseMC").length > 0){
		getHiddenTag("expenseMC").val(getInputTag("expenseMC").val());
	}
	
	//투자비
	if(getInputTag("expenseInvest").length > 0){
		getHiddenTag("expenseInvest").val(getInputTag("expenseInvest").val());
	}
	
	//개발비
	if(getInputTag("expenseDevelop").length > 0){
		getHiddenTag("expenseDevelop").val(getInputTag("expenseDevelop").val());
	}
	
	//인건비
	if(getInputTag("expensePeople").length > 0){
		getHiddenTag("expensePeople").val(getInputTag("expensePeople").val());
	}
	
	//경상개발비
	if(getInputTag("expenseCurrentDevelop").length > 0){
		getHiddenTag("expenseCurrentDevelop").val(getInputTag("expenseCurrentDevelop").val());
	}
	
	//참조 문서, 참조 문서 파일 캐시
	var refDocGridId = refDoc_myGridID;
	if(refDocGridId != null){
		//문서
		addedRefDocList = AUIGrid.getGridData(refDocGridId);
		
		addedRefDocFiles = referenceDocFileCache;
	}
	
	//관련 품목
	var relPartGridId = add_addDetailProject_myGridID;
	if(relPartGridId != null){
		addedRelPartList = AUIGrid.getGridData(relPartGridId);
	}
	
}

//pageCaching() 기억한 값을 Include변경 시 다시 로드함
function loadPageCache(){
	
	//프로젝트 정보
	//프로젝트 명
	if(getInputTag("projectName").length > 0){
		if(getHiddenTag("projectName").val().length > 0){
			getInputTag("projectName").val(getHiddenTag("projectName").val());
		}
	}
	
	//Jira ID(select2에서 제어)
	
	//프로젝트 유형
	if($("select[id=productGubun]").length > 0){
		if(getHiddenTag("productGubun").val().length > 0){
			$("select[id=productGubun]").val(getHiddenTag("productGubun").val()).prop("selected", true);
			
			$(".hiddenOpt").detach();
		}
	}
	
	//개발제품 명
	if(getInputTag("productType").length > 0){
		if(getHiddenTag("productType").val().length > 0){
			getInputTag("productType").val(getHiddenTag("productType").val());
		}
	}
	
	//계획 시작일
	if(getInputTag("projectPlanStartDate").length > 0){
		if(getHiddenTag("projectPlanStartDate").val().length > 0){
			getInputTag("projectPlanStartDate").val(getHiddenTag("projectPlanStartDate").val());
		}
	}
	
	//계획 종료일
	if(getInputTag("projectPlanEndDate").length > 0){
		if(getHiddenTag("projectPlanEndDate").val().length > 0){
			getInputTag("projectPlanEndDate").val(getHiddenTag("projectPlanEndDate").val());
		}
	}
	
	//설명
	if($("textarea[id=contents]").length > 0){
		if(getHiddenTag("projectDescription").val().length > 0){
			$("textarea[id=contents]").val(getHiddenTag("projectDescription").val());
		}
	}
	
	//MM
	if(getInputTag("expenseMM").length > 0){
		if(getHiddenTag("expenseMM").val().length > 0){
			getInputTag("expenseMM").val(getHiddenTag("expenseMM").val());
		}
	}
	
	//환종
	if($("select[id=expenseCurrency]").length > 0){
		
		$("select[id=expenseCurrency]").val(getHiddenTag("expenseCurrency").val()).prop("selected", true);
	}
	
	//MC
	if(getInputTag("expenseMC").length > 0){
		if(getHiddenTag("expenseMC").val().length > 0){
			getInputTag("expenseMC").val(getHiddenTag("expenseMC").val());
		}
	}
	
	//투자비
	if(getInputTag("expenseInvest").length > 0){
		if(getHiddenTag("expenseInvest").val().length > 0){
			getInputTag("expenseInvest").val(getHiddenTag("expenseInvest").val());
		}
	}
	
	//개발비
	if(getInputTag("expenseDevelop").length > 0){
		if(getHiddenTag("expenseDevelop").val().length > 0){
			getInputTag("expenseDevelop").val(getHiddenTag("expenseDevelop").val());
		}
	}
	
	//인건비
	if(getInputTag("expensePeople").length > 0){
		if(getHiddenTag("expensePeople").val().length > 0){
			getInputTag("expensePeople").val(getHiddenTag("expensePeople").val());
		}
	}
	
	//경상개발비
	if(getInputTag("expenseCurrentDevelop").length > 0){
		if(getHiddenTag("expenseCurrentDevelop").val().length > 0){
			getInputTag("expenseCurrentDevelop").val(getHiddenTag("expenseCurrentDevelop").val());
		}
	}
	
	//참조 문서, 참조 문서 파일 캐시
	if(addedRefDocList.length > 0){
		var refDocGridId = includePageGridId_refDoc;
		
		if(refDocGridId != null){                               
			var asdf = addedRefDocList;                           
			AUIGrid.addRow(refDocGridId, addedRefDocList, "last");    
			
			referenceDocFileCache = addedRefDocFiles;
		}  
	}

	
	//관련 품목
	if(addedRelPartList.length > 0){
		var partGridId = add_addDetailProject_myGridID;
		
		if(partGridId != null){
			AUIGrid.addRow(add_addDetailProject_myGridID, addedRelPartList, "last");
		}
	}
	
}

function getOutputTemplate(productGubun){
	
	if(productGubun.length > 0){
		var url = getURLString("/admin/getOutputTemplateList");
		var param = new Object();
		param.gateCode = productGubun;
		
		var data = ajaxCallServer(url, param, null, null);
		
		addedOutput = data.list;
	}
	
}

function attachEditEndEvent(eventTag){
	
	if(eventTag == "select"){
		$("select").bind("change", function(){
			pageCaching();
		});
	}else if(eventTag == "span"){
		$(eventTag).bind("click", function(){
			pageCaching();
		});
	}else{
		$(eventTag).bind("focusout", function(){
			pageCaching();
		});
	}
	
		
}

function getHiddenTag(tagId){
	var tag = $("[name=projectForm] input[type=hidden][id="+ tagId +"]");
	return tag;
}

function getInputTag(tagId){
	var tag = $("input[id="+tagId+"]").not("input[type=hidden]");
	return tag;
}

//끝에 한 글자가 잘리는 현상..따로 함수로 분리. 이벤트는 smarteditor2.jsp 참고
function editorCaching(inputValue){
	
	var editorFrame = document.querySelector("iframe");
	if(editorFrame != null){
		var textArea = editorFrame.contentWindow.document.querySelector("iframe").contentWindow.document.querySelector(".se2_inputarea");
		getHiddenTag("projectDescription").val(inputValue);
	}
}

</script>
<div class="product pop">
	<div class="tap pt20">
		<ul>
			<li onclick="loadIncludePage(this);" data-url="${tl:getURLString('/project/include_addDetailProject')}">${tl:getMessage('프로젝트 정보')}</li>
			<li onclick="loadIncludePage(this);" data-url="${tl:getURLString('/project/include_addGateOutput')}">${tl:getMessage('GATE 정보 & 산출물')}</li>
			<li onclick="loadIncludePage(this);" data-url="${tl:getURLString('/project/include_addDetailMember')}">${tl:getMessage('구성원')}</li>
		</ul>
		<div class="tapbutton">
		<!--i_update 노란색  i_delete 빨간색  i_read 퍼런색 i_close 연한회색 초록색-->
			<button type="button" class="s_create" onclick="save()">${tl:getMessage('저장')}</button>
			<!--<button type="button" class="i_delete" onclick="test()">${tl:getMessage('테스트')}</button>-->
			<%-- <c:if test="${doc.recallBtn()}">
				<button type="button" class="s_bt03" onclick="javascript:recallApproval('${doc.oid}')">${tl:getMessage('회수')}</button>
			</c:if>
			<c:if test="${doc.withdrawnBtn()}">
				<button type="button" class="s_bt03" onclick="javascript:discardDoc()">${tl:getMessage('폐기')}</button>
			</c:if> --%>
		</div>
	</div>
	<!--//tap -->
	<div class="con pl25 pr25 pb15" id="includePage">
	</div>
</div>
<form name="projectForm" id="projectForm" method="post" enctype="multipart/form-data">
	<input type="hidden" name="projectName" id="projectName" value=""/>
	<input type="hidden" name="projectJiraId" id="projectJiraId" value=""/>
	<input type="hidden" name="projectJiraIdDisplay" id="projectJiraIdDisplay" value=""/>
	<input type="hidden" name="productGubun" id="productGubun" value=""/>
	<input type="hidden" name="productType" id="productType" value=""/>
	<input type="hidden" name="projectPlanStartDate" id="projectPlanStartDate" value=""/>
	<input type="hidden" name="projectPlanEndDate" id="projectPlanEndDate" value=""/>
	<input type="hidden" name="projectDescription" id="projectDescription" value=""/>
	<input type="hidden" name="expenseMM" id="expenseMM" value=""/>
	<input type="hidden" name="expenseCurrency" id="expenseCurrency" value="KRW"/>
	<input type="hidden" class="moneyExpression" name="expenseInvest" id="expenseInvest" value=""/>
	<input type="hidden" class="moneyExpression" name="expensePeople" id="expensePeople" value=""/>
	<input type="hidden" class="moneyExpression" name="expenseDevelop" id="expenseDevelop" value=""/>
	<input type="hidden" class="moneyExpression" name="expenseCurrentDevelop" id="expenseCurrentDevelop" value=""/>
	<input type="hidden" class="moneyExpression" name="expenseMC" id="expenseMC" value=""/>
</form>
