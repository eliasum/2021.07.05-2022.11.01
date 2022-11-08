<xsl:stylesheet version="1.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text" encoding="UTF-8"/>

  <!--2021.11.12 16:13 IMM-->

  <!-- https://xsltdev.ru/xslt/xsl-template/
        - Элемент верхнего уровня xsl:template определяет в преобразовании
        шаблонное правило, или просто шаблон.
        
        match - необязательный атрибут, задает паттерн — образец узлов дерева, 
        для преобразования которых следует применять этот шаблон.
        Паттерн на языке XPath.
        
        https://xsltdev.ru/xslt/xsl-for-each/
        - Элемент xsl:for-each используется для создания в выходящем документе
        повторяемых частей структуры.
        Обязательный атрибут select указывает выражение (паттерн на языке
        XPath), результатом вычисления которого должно быть множество узлов.
        Шаблон, содержащийся в xsl:for-each, будет выполнен процессором для 
        каждого узла этого множества.
        
        - // любой корень (any root)
        * любой тэг (any tagName)
        
        - ancestor:: — возвращает множество предков (* - всех)
        
        https://xsltdev.ru/xslt/xsl-value-of/
        - Элемент xsl:value-of служит для вычисления значений выражений.
        
        select - обязательный атрибут, задает выражение, которое вычисляется
        процессором, затем преобразовывается в строку и выводится в 
        результирующем дереве в виде текстового узла. Процессор не станет
        создавать текстовый узел, если результатом вычисления выражения была
        пустая строка. В целях оптимизации дерева, соседствующие текстовые узлы
        будут объединены в один.
        
        - Инструкция xsl:if позволяет создавать простые условия типа "если-то".
        
        test - обязательный атрибут, задает выражение, которое вычисляется и 
        приводится к булевому типу. В том и только том случае, если выражение
        имеет значение true, процессор выполняет шаблон, содержащийся в xsl:if. 
   -->

  <!--Шаблон для корневого узла (узла документа)-->
  <!--В коде один шаблон, который применяется ко всему документу.-->
  <xsl:template match="/">
    <xsl:text>
CREATE TABLE IF NOT EXISTS public."Dictionary"
(
    key integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    "XPath" character varying(200) COLLATE pg_catalog."default",
    "Format" character varying(100) COLLATE pg_catalog."default",
    CONSTRAINT "Dictionary_pkey" PRIMARY KEY (key)
)
  </xsl:text>
    <xsl:text>&#10;</xsl:text>    
    <!--Цикл по всем атрибутам @format-->
    <xsl:for-each select="//@format">
      <xsl:text>INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("</xsl:text>
      <!--Выбрать атрибуты value-->
      <!--Выбрать всё (*) множество предков атрибута format (для атрибута 
      без разницы, "ancestor::*" или "ancestor-or-self::*"). Цикл начинается
      с предка верхнего уровня и далее вниз по цепочке.-->
      <xsl:for-each select="ancestor::*">
        <!--name() или name(.) или (.) - печатаем имя текущего узла, 
        начиная с предка верхнего уровня-->
        <xsl:value-of select="name()"/>
        <!--Если узел имеет имя Item, тогда выводим значение его атрибута key-->
        <xsl:if test="name()='Item'">
          <xsl:text>[@key='</xsl:text>
          <xsl:value-of select="@key"/>
          <xsl:text>']</xsl:text>
        </xsl:if>
        <xsl:text>/</xsl:text>
        <!--Если текущий узел имеет атрибут format, тогда выводим значение
        его атрибута format-->
        <xsl:if test="(.)[@format]">
          <xsl:text>@format","</xsl:text>
          <xsl:value-of select="@format"/>
          <xsl:text>");&#10;&#10;</xsl:text>
        </xsl:if>
        <!--Конец итерации (цикла) перебора всех предков узла с атрибутом format-->
      </xsl:for-each>
    <!--Конец итерации (цикла) перебора всех атрибутов @format-->
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
