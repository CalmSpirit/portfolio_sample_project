<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!-- 각 화면 개발시 Tag 복사해서 붙여넣고 사용할것 -->    
<%@ taglib prefix="c"		uri="http://java.sun.com/jsp/jstl/core"			%>
<%@ taglib prefix="tl" 	uri="/WEB-INF/tlds/tl-functions.tld"%>
<style>

.SumoSelect {
    width: 58%;
}
</style>
<script>
$(document).ready(function(){
	//enter key pressed event
	$("#searchForm").keypress(function(e){
		if(e.keyCode==13){
			search();
		}
	});
	
	getDocAttributes();
	
	getDocumentTypes();
	
	//lifecycle list
	getLifecycleList("LC_Default");
	
	//grid setting
	createAUIGrid(columnLayout);
	
	//get grid data(트리 존재시 트리에서 로딩)
	getGridData();
	
	//프로젝트/설계변경 자동완성 초기화
	initAutocompleteEChangeProject();
});

//AUIGrid 생성 후 반환 ID
var myGridID;

//현재 페이지
var page = 1;

//row 로딩 개수
var rows = 20;

// 중복 요청을 피하기 위한 플래그
var nowRequesting = false;

//마지막 페이지 여부
var isLastPage = false;

//소트 값
var sortValue = "";

//소트 값으로 소팅되었는지 체크하는 값
var sortCheck = true;

//AUIGrid 칼럼 설정
var columnLayout = [
	{ 
		dataField : "location", 
		headerText : "${tl:getMessage('문서 분류')}", 
		width:"10%", 
		style:"AUIGrid_Left",
		filter : {
			showIcon : true,
			iconWidth:20,
		}},
	{ 
		dataField : "docAttributeName", 
		headerText : "${tl:getMessage('문서 속성')}", 
		width:"7%",	
		style:"AUIGrid_Left", 
		filter : {
			showIcon : true,
			iconWidth:20
		}},
	{ 
		dataField : "docType", 
		headerText : "${tl:getMessage('문서 구분')}", 
		width:"6%",	
		style:"AUIGrid_Left", 
		filter : {
			showIcon : true,
			iconWidth:20
		}},
	{ 
		dataField : "number", 
		headerText : "${tl:getMessage('문서 번호')}",	 
		width:"8%", 
		style:"AUIGrid_Left", 
		sortValue : "master>number",
		filter : {
			showIcon : true,
			iconWidth:20
		},
		renderer : {
			type : "LinkRenderer",
			baseUrl : "javascript", // 자바스크립 함수 호출로 사용하고자 하는 경우에 baseUrl 에 "javascript" 로 설정
			// baseUrl 에 javascript 로 설정한 경우, 링크 클릭 시 callback 호출됨.
			jsCallback : function(rowIndex, columnIndex, value, item) {
				var oid = item.oid;
				openView(oid);
			}
		}},
	{ 
		dataField : "name", 
		headerText : "${tl:getMessage('문서 명')}", 
		width:"*", 
		style:"AUIGrid_Left", 
		sortValue : "master>name",
		filter : {
			showIcon : true,
			iconWidth:20
		}},
	{ 
		dataField : "version", 
		headerText : "${tl:getMessage('버전')}", 
		sortValue : "version",
		width:"5%",
		filter : {
			showIcon : true,
			iconWidth:20
		}},
	{ 
		dataField : "stateName", 
		headerText : "${tl:getMessage('상태')}", 
		width:"5%",
		filter : {
			showIcon : true,
			iconWidth:20
		}},
	{ 
		dataField : "creatorFullName",		
		headerText : "${tl:getMessage('등록자')}",		
		width:"6%",
		filter : {
			showIcon : true,
			iconWidth:20
		}},
	{ 
		dataField : "createDateFormat",	
		headerText : "${tl:getMessage('등록일')}",	
		width:"6%",
		filter : {
			showIcon : true,
			iconWidth:20
		}},
	{ 
		dataField : "modifierFullName",
		headerText : "${tl:getMessage('수정자')}",
		width:"6%",
		filter : {
			showIcon : true,
			iconWidth:20
		}},
	{ 
		dataField : "modifyDateFormat",
		headerText : "${tl:getMessage('수정일')}",
		width:"6%",
		filter : {
			showIcon : true,
			iconWidth:20
		}},
	{ 
		dataField : "relPartsString", 
		headerText : "${tl:getMessage('관련 품목')}", 
		width:"7%", style:"AUIGrid_Left",
		sortValue : "master>name",
		filter : {
			showIcon : true,
			iconWidth:20
		}},
	{ 
		dataField : "eChangeProjectsNumberString", 
		headerText : "${tl:getMessage('프로젝트/설변 번호')}", 
		width:"9%", style:"AUIGrid_Left",	
		sortValue : "master>name",
		filter : {
			showIcon : true,
			iconWidth:20
		}},
	{ 
		dataField : "eChangeProjectsNameString", 
		headerText : "${tl:getMessage('프로젝트/설변 명')}", 
		width:"9%", style:"AUIGrid_Left",	
		sortValue : "master>name",
		filter : {
			showIcon : true,
			iconWidth:20
		}},
	
];

//AUIGrid 를 생성합니다.
function createAUIGrid(columnLayout) {
	
	// 그리드 속성 설정
	var gridPros = {
		
		selectionMode : "multipleCells",
		
		showSelectionBorder : true,
		
		noDataMessage : gridNoDataMessage,
		
		rowIdField : "_$uid",
		
		showRowNumColumn : true,
		
		showEditedCellMarker : false,
		
		wrapSelectionMove : true,
		
		showRowCheckColumn : true,
		
		enableFilter : true,
		
		enableMovingColumn : true,
		
		headerHeight : gridHeaderHeight,
		
		rowHeight : gridRowHeight,
		
		enableMovingColumn : true,
		
	};

	// 실제로 #grid_wrap 에 그리드 생성
	myGridID = AUIGrid.create("#grid_wrap", columnLayout, gridPros);
	
	// 셀 클릭 이벤트 바인딩
	AUIGrid.bind(myGridID, "cellClick", auiGridCellClickHandler);
	
	// 스크롤 체인지 이벤트 바인딩
	AUIGrid.bind(myGridID, "vScrollChange", vScollChangeHandelr);
	
	// 헤더 클릭 이벤트 바인딩
	//AUIGrid.bind(myGridID, "headerClick", auiGridHeaderClickHandler);
	
	var gridData = new Array();
	AUIGrid.setGridData(myGridID, gridData);
}

function getGridData(){
	
	$("#searchForm").attr("action", getURLString("/doc/searchDocScrollAction"));
	
	var param = new Object();
	
	param["page"] = page;
	param["rows"] = rows;
	//param["sortValue"] = sortValue;
	//param["sortCheck"] = sortCheck;
	
	if(page == 1) {
		AUIGrid.showAjaxLoader(myGridID);
	}
	
	var data = formSubmit("searchForm", param, null, null);
	
	// 그리드 데이터
	var gridData = data.list;
	if(data.result){
		
		var count = $("#count").html();
		
		if(page == 1) {
			// 그리드에 데이터 세팅(첫 요청)
			
			AUIGrid.setGridData(myGridID, gridData);	
			count = gridData.length;
		} else {
			// 그리드에 데이터 세팅(추가 요청)
			AUIGrid.appendData(myGridID, gridData);
			
			count = parseInt(count) + gridData.length;
		}
		
		$("#count").html(count);
		$("#total").html(data.totalSize);
		$("#sessionId").val(data.sessionId);
		
		if(gridData.length == 0) {
			isLastPage = true;
		}
		
		AUIGrid.removeAjaxLoader(myGridID);
		
		nowRequesting = false;
		
	}
	
}

//셀 클릭 핸들러
function auiGridCellClickHandler(event) {
	
	var dataField = event.dataField;
	var oid = event.item.oid;
	
}

//헤더 클릭 핸들러
function auiGridHeaderClickHandler(event) {
	
	isLastPage = false;
	page = 1;
	$("#sessionId").val("");
	
	var dataField = event.dataField;
	
	if(event.item.sortValue == null){
		return true;
	}
	
	if(sortValue == event.item.sortValue){
		if(sortCheck == false) {
			sortValue = "";
			sortCheck = true;
			getGridData();
			
			return false;
		}
		sortCheck = !sortCheck;
	}
	
	sortValue = event.item.sortValue;
	
	getGridData();
	
	return false;
}

//스크롤 체인지 핸들어에서 무리한 작업을 하면 그리드 퍼포먼스가 떨어집니다.
//따라서 무리한 DOM 검색은 자제하십시오.
function vScollChangeHandelr(event) {
	
	// 스크롤 위치가 마지막과 일치한다면 추가 데이터 요청함
	if(event.position == event.maxPosition) {
		if(!isLastPage) {
			if(!nowRequesting) {
				page++;
				getGridData();
			}
		}
	}
	
}

//검색
function search(){
	isLastPage = false;
	page = 1;
	sortValue = "";
	$("#sessionId").val("");
	getGridData();
}

//검색조건 초기화
function reset(){
	var locationDisplay = $("#locationDisplay").val();
	$("#searchForm")[0].reset();
	$("#locationDisplay").val(locationDisplay);
	//AUIGrid.setSelectionByIndex(docFolder_tree_myGridID, 0, 0);
	//search();
}

//필터 초기화
function resetFilter(){
    AUIGrid.clearFilterAll(myGridID);
}

function xlsxExport() {
	AUIGrid.setProperty(myGridID, "exportURL", getURLString("/common/xlsxExport"));
	
	 // 엑셀 내보내기 속성
	  var exportProps = {
			 postToServer : true,
	  };
	  // 내보내기 실행
	  AUIGrid.exportToXlsx(myGridID, exportProps);
}

function changeLoadingRows(selected){
	rows = parseInt($(selected).val());
	isLastPage = false;
	page = 1;
	sortValue = "";
	$("#sessionId").val("");
	getGridData();
}

function setOutPeople(id, item){
	$("#" + id).trigger("change");
	$("#" + id).append("<option value='" + item.oid + "' selected>" + item.name +"[" + item.personalId + "]"  + "</option>");
	$("#" + id).val(item.oid);
}

</script>
<div class="product">
	<!-- button -->
	<div class="seach_arm pt10 pb5">
		<div class="leftbt"><h4><img class="pointer" onclick="switchPopupDiv(this);" src="/Windchill/jsp/portal/images/minus_icon.png">&nbsp;${tl:getMessage('검색 조건')}</h4></div>
		<div class="rightbt">
			<button type="button" class="i_read" style="width: 70px;" id="searchBtn" onclick="search();">${tl:getMessage('검색')}</button>
			<button type="button" class="i_read" style="width: 70px;" id="switchDetailBtn" onclick="switchDetailBtn();">${tl:getMessage('상세검색')}</button>
			<button type="button" class="i_update" style="width: 70px;" id="resetBtn" onclick="reset();">${tl:getMessage('초기화')}</button>
		</div>
	</div>
	<!-- //button -->
	<!-- pro_table -->
	<div class="pro_table mr30 ml30">
		<form name="searchForm" id="searchForm" style="margin-bottom: 0px;">
			<input type="hidden" id="location" name="location" value="">
			<input type="hidden" id="sessionId" name="sessionId" value="">
			<input type="hidden" id="mode" name="mode" value="search">
			<input type="hidden" id="cFolderOid" name="cFolderOid" value="">
			<input type="hidden" id="cFolderPath" name="cFolderPath" value="">
			<table class="mainTable">
				<colgroup>
					<col style="width:15%">
					<col style="width:35%">
					<col style="width:15%">
					<col style="width:35%">
				</colgroup>	
				<tbody>
					<tr>
						<th scope="col">${tl:getMessage('문서 분류')}</th>
						<td><input type="text" id="locationDisplay" name="locationDisplay" class="w58" disabled></td>
						<th scope="col">${tl:getMessage('버전')}</th>
						<td>
							<input type="radio" id="version" name="version" value="new" checked>
							<label>${tl:getMessage('최신 버전')}</label>
							<span style="width: 10%; display: inline-block;"></span>
							<input type="radio" id="version" name="version" value="all">
							<label>${tl:getMessage('모든 버전')}</label>
						</td>
					</tr>
					<tr>
						<th scope="col">${tl:getMessage('문서 명')}</th>
						<td><input type="text" id="name" name="name" class="w58"></td>
						<th scope="col">${tl:getMessage('상태')}</th>
						<td>
							<select class="multiSelect w10" id="state" name="state" multiple style="height:20px;overflow-y: hidden;">
							</select>
						</td>
					</tr>
					<tr>
						<th scope="col">${tl:getMessage('문서 속성')}</th>
						<td>
							<select class="multiSelect w10" id="docAttribute" name="docAttribute" multiple style="height:20px;overflow-y: hidden;">
							</select>
						</td>
						<th scope="col">${tl:getMessage('문서 구분')}</th>
						<td>
						<div class="pro_view">
							<select class="multiSelect w10" id="docType" name="docType" multiple style="height:20px;overflow-y: hidden;">
							</select>
						</div>
						</td>
					</tr>	
					<tr>
						<th scope="col">${tl:getMessage('설계변경/프로젝트 명')}</th>
						<td>
						<input type="text" id="eChangeProjectName" name="eChangeProjectName" class="w58">	
						</td>
						<th scope="col">${tl:getMessage('설계변경/프로젝트 번호')}</th>
						<td>
						<select class="searchEChangeProject" id="eChangeProjectNumber" name="eChangeProjectNumber" multiple data-param="doc" data-width="58%"></select>
						<span class="pointer verticalMiddle" onclick="javascript:deleteUser('eChangeProjectNumber');"><img class="verticalMiddle" src='/Windchill/jsp/portal/images/delete_icon.png'></span>
						</td>
					</tr>
					<tr class="switchDetail">
						<th scope="col">${tl:getMessage('등록일')}</th>
						<td class="calendar">
					        <input type="text" class="datePicker w21" name="predate" id="predate" readonly/>
							~
							<input type="text" class="datePicker w21" name="postdate" id="postdate" readonly/>
						</td>
						<th scope="col">${tl:getMessage('수정일')}</th>
						<td class="calendar">
					        <input type="text" class="datePicker w21" name="predate_modify" id="predate_modify" readonly/>
							~
							<input type="text" class="datePicker w21" name="postdate_modify" id="postdate_modify" readonly/>
						</td>
					</tr>
					<tr class="switchDetail">
						<th scope="col">${tl:getMessage('등록자')}</th>
						<td>
							<div class="pro_view">
								<select class="searchUser" id="creator" name="creator" multiple data-width="58%" style="width: 58%;">
								</select>
								<span class="pointer verticalMiddle" onclick="javascript:openUserPopup('creator', 'multi');"><img class="verticalMiddle" src="/Windchill/jsp/portal/images/search_icon2.png"></span>
								<span class="pointer verticalMiddle" onclick="javascript:deleteUser('creator');"><img class="verticalMiddle" src='/Windchill/jsp/portal/images/delete_icon.png'></span>
							</div>
						</td>
						<th scope="col">${tl:getMessage('수정자')}</th>
						<td>
							<div class="pro_view">
								<select class="searchUser" id="modifier" name="modifier" multiple data-width="58%">
								</select>
								<span class="pointer verticalMiddle" onclick="javascript:openUserPopup('modifier', 'multi');"><img class="verticalMiddle" src="/Windchill/jsp/portal/images/search_icon2.png"></span>
								<span class="pointer verticalMiddle" onclick="javascript:deleteUser('modifier');"><img class="verticalMiddle" src='/Windchill/jsp/portal/images/delete_icon.png'></span>
							</div>
						</td>
					</tr>
					<tr class="switchDetail">
						<th scope="col">${tl:getMessage('문서 번호')}</th>
						<td>
						<select class="searchRelatedObject" id="relatedDoc" name="relatedDoc" multiple data-param="doc" data-width="58%"></select>
						<span class="pointer verticalMiddle" onclick="javascript:deleteUser('relatedDoc');"><img class="verticalMiddle" src='/Windchill/jsp/portal/images/delete_icon.png'></span>
						</td>
					</tr>
					
				</tbody>
			</table>
	</form>	
	</div>
	<!-- //pro_table -->
	<!-- button -->
	<div class="seach_arm pt5 pb5">
		<div class="leftbt">
			<span>
				<img class="" src="/Windchill/jsp/portal/images/t_icon.png"> ${tl:getMessage('검색 결과')} (<span id="count">0</span>/<span id="total">0</span>)
			</span>
		</div>
		<div class="rightbt">
			<img class="pointer mb5" id="favorite" data-type="false" data-oid="" onclick="add_favorite();" src="/Windchill/jsp/portal/images/favorites_icon_b.png" border="0"/>
			<select id="rows" name="rows" style="width:100px;" onchange="javascript:changeLoadingRows(this)">
				<option value="20">20</option>
				<option value="40">40</option>
				<option value="60">60</option>
				<option value="80">80</option>
				<option value="100">100</option>
			</select>
			<button type="button" class="i_read" style="width:100px" onclick="resetFilter();">${tl:getMessage('필터 초기화')}</button>
			<button type="button" class="i_read" style="width:100px" onclick="xlsxExport();">${tl:getMessage('엑셀 다운로드')}</button>
			<img class="pointer mb5" onclick="excelDown('searchForm', 'excelDownDoc');" src="/Windchill/jsp/portal/icon/fileicon/xls.gif" border="0">
		</div>
	</div>
	<!-- //button -->
	<!-- table list-->
	<div class="table_list">
		<div class="list" id="grid_wrap" style="height:550px"></div>
	</div>
	<!-- //table list-->
</div>