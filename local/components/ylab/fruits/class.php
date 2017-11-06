<?php
class FruitsComponent extends CBitrixComponent
{
    private function getFruits()
    {
        if (CModule::IncludeModule("iblock")) {
            // id тестового инфоблока задаётся вручную
            $id_iblock = 16;
            
            // выбираем список элементов тестового инфоблока, проверяем, передаётся ли параметр с конкретным элементом
            $arSelect = Array("ID");
            $arFilter = $_GET["id"] ? Array("IBLOCK_ID" => $id_iblock, "ID" => $_GET["id"]) : Array("IBLOCK_ID" => $id_iblock);
            $listElement = CIBlockElement::GetList(array(),$arFilter,false,false, $arSelect);
            if ($listElement->result->num_rows == 0) return 'no such component';

            // формируем результирующий массив, "пробегаясь" по отобранным элементам
            $res = array();
            while($id_element = $listElement->Fetch())
            {
                $element = CIBlockElement::GetProperty($id_iblock, $id_element["ID"]);
                $element = $element->Fetch();
                $res[]["id"] = $id_element["ID"];
                $res[]["title"] = $element["VALUE"];
            }

            return $res ? $res : 'empty result';
        }
    }
    public function executeComponent()
    {
        global $APPLICATION;
        $APPLICATION->RestartBuffer();
        $this->arResult = $this->getFruits();
        $this->includeComponentTemplate();
    }
}