   M S B A M L   `   `   `  ????R  NDefectCheckControlUsing, Version=1.0.0.0, Culture=neutral, PublicKeyToken=nullA%clr-namespace:DefectCheckControlUsingDefectCheckControlUsing  5   	   T PDefectCheckControlLibrary, Version=1.0.0.0, Culture=neutral, PublicKeyToken=nullhJclr-namespace:DefectCheckControlLibrary;assembly=DefectCheckControlLibraryDefectCheckControlLibrary 5   	   (    "DefectCheckControlUsing.MainWindow   5   	   \ XPresentationFramework, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35R NWindowsBase, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35W SPresentationCore, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35D 9http://schemas.microsoft.com/winfx/2006/xaml/presentation    R NSystem.Xaml, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089:x,http://schemas.microsoft.com/winfx/2006/xaml     5   	   @d2http://schemas.microsoft.com/expression/blend/2008     5   	   Jmc;http://schemas.openxmlformats.org/markup-compatibility/2006     5   	   7local%clr-namespace:DefectCheckControlUsing     5   	   ^controlJclr-namespace:DefectCheckControlLibrary;assembly=DefectCheckControlLibrary     5   	     ? Title$  
MainWindow??5
   	    ? DataContext 5      ? 5   
   ,  &System.Windows.Data.DataSourceProvider   IsInitialLoadEnabled .  ? IsAsynchronous .  .??5      ?X?X<Product xmlns="" title="Проверяемое изделие">
                    <Settings title="Изделие">
                        <Brand title="Тип" description="Торговая марка">
                            <Shield title="Тип экрана" description="Выбрать другой тип экрана изделия">
                                <Item key="Simple" title="Простой" description="Изделие с простым типом экрана" />
                                <Item key="Invert" title="Инвертный" description="Изделие с инвертным типом экрана" />
                            </Shield>
                            <Item key="1" title="АО" description="" />
                            <Item key="2" title="ООО" description="" />
                        </Brand>
                        <Phosphor title="Люминофор" description="Люминофор изделия">
                            <Type title="Тип" description="Тип люминофора">
                                <Item key="1" title="ВОЭ" description="(!) Узнать у технолога ТТ 031.СЕ.307">
                                    <Camcoder title="Видеокамера" description="Настройки видеокамеры">
                                        <Exposition value="90" title="Выдержка" description="Выдержка видеокамеры" unit="мс" />
                                        <Gain value="0.2857" title="Усиление" description="Усиление видеокамеры" unit="%" />
                                    </Camcoder>
                                </Item>
                                <Item key="2" title="Мт.ст" description="(!) Узнать у технолога ТТ 031.СЕ.307">
                                    <Camcoder title="Видеокамера" description="Настройки видеокамеры">
                                        <Exposition value="45" title="Выдержка" description="Выдержка видеокамеры" unit="мс" />
                                        <Gain value="0.5824" title="Усиление" description="Усиление видеокамеры" unit="%" />
                                    </Camcoder>
                                </Item>
                            </Type>
                        </Phosphor>
                        <Defect title="Дефект" description="Дефект изделия">
                            <Type title="Тип" description="Тип дефекта">
                                <Item key="01" title="нер.стр." />
                                <Item key="02" title="точ.нер" />
                                <Item key="03" title="св пол" />
                                <Item key="04" title="свп" />
                                <Item key="05" title="свт" />
                                <Item key="06" title="сер п" />
                                <Item key="07" title="сер т" />
                                <Item key="08" title="полоса" />
                                <Item key="09" title="тт" />
                                <Item key="10" title="скопл. ТТ" />
                                <Item key="11" title="тт с ореол" />
                                <Item key="12" title="цар" />
                                <Item key="13" title="тт ВОЭ" />
                                <Item key="14" title="тем.пол ВОЭ" />
                                <Item key="15" title="нер ВОЭ" />
                                <Item key="16" title="серость ВОЭ" />
                                <Item key="17" title="хром" />
                                <Item key="18" title="прочее" />
                                <Item key="19" title="Нерав. ОП" />
                                <Item key="20" title="затек" />
                                <Item key="21" title="Пятно Ал" />
                                <Item key="22" title="Треск ВОЭ" />
                                <Item key="23" title="Скол ВОЭ" />
                                <Item key="24" title="Ворс" />
                                <Item key="25" title="Без высоты" />
                            </Type>
                        </Defect>
                        <Resume title="Резюме" description="Резюме по изделию">
                            <Type title="Тип" description="Тип резюме">
                                <Item key="1" title="Годен" />
                                <Item key="2" title="Брак" />
                            </Type>
                        </Resume>
                        <Slot title="Позиция" description="Позиция изделия" number="№ УЛ">
                            <Item key="01" phosphor="phosphor01" resume="resume01">
                                <!--phosphor = здесь должен быть ключ, выбранного оператором типа люминофора-->
                                <!--resume = здесь должен быть ключ, выбранного оператором типа резюме-->
                                <Defect title="Выбранные дефекты изделия" description="Выбранные оператором дефекты изделия">
                                    <!--Item key=" 2" description="(!) приведён в качестве примера, показывает, что оператор выбрал ключ определённого дефекта"/>
					                <   Item key=" 7" description="(!) приведён в качестве примера, показывает, что оператор выбрал ключ определённого дефекта"/>
					                <   Item key="11" description="(!) приведён в качестве примера, показывает, что оператор выбрал ключ определённого дефекта"/-->
                                </Defect>
                            </Item>
                            <Item key="02" phosphor="phosphor02" resume="">
                                <Defect title="Выбранные дефекты изделия" description="Выбранные оператором дефекты изделия" />
                            </Item>
                            <Item key="03" phosphor="" resume="">
                                <Defect title="Выбранные дефекты изделия" description="Выбранные оператором дефекты изделия" />
                            </Item>
                            <Item key="04" phosphor="" resume="">
                                <Defect title="Выбранные дефекты изделия" description="Выбранные оператором дефекты изделия" />
                            </Item>
                            <Item key="05" phosphor="" resume="">
                                <Defect title="Выбранные дефекты изделия" description="Выбранные оператором дефекты изделия" />
                            </Item>
                            <Item key="06" phosphor="" resume="">
                                <Defect title="Выбранные дефекты изделия" description="Выбранные оператором дефекты изделия" />
                            </Item>
                            <Item key="07" phosphor="" resume="">
                                <Defect title="Выбранные дефекты изделия" description="Выбранные оператором дефекты изделия" />
                            </Item>
                            <Item key="08" phosphor="" resume="">
                                <Defect title="Выбранные дефекты изделия" description="Выбранные оператором дефекты изделия" />
                            </Item>
                            <Item key="09" phosphor="" resume="">
                                <Defect title="Выбранные дефекты изделия" description="Выбранные оператором дефекты изделия" />
                            </Item>
                            <Item key="10" phosphor="" resume="">
                                <Defect title="Выбранные дефекты изделия" description="Выбранные оператором дефекты изделия" />
                            </Item>
                            <Item key="11" phosphor="" resume="">
                                <Defect title="Выбранные дефекты изделия" description="Выбранные оператором дефекты изделия" />
                            </Item>
                            <Item key="12" phosphor="" resume="">
                                <Defect title="Выбранные дефекты изделия" description="Выбранные оператором дефекты изделия" />
                            </Item>
                            <Item key="13" phosphor="" resume="">
                                <Defect title="Выбранные дефекты изделия" description="Выбранные оператором дефекты изделия" />
                            </Item>
                            <Item key="14" phosphor="" resume="">
                                <Defect title="Выбранные дефекты изделия" description="Выбранные оператором дефекты изделия" />
                            </Item>
                            <Item key="15" phosphor="" resume="">
                                <Defect title="Выбранные дефекты изделия" description="Выбранные оператором дефекты изделия" />
                            </Item>
                            <Item key="16" phosphor="" resume="">
                                <Defect title="Выбранные дефекты изделия" description="Выбранные оператором дефекты изделия" />
                            </Item>
                            <Item key="17" phosphor="" resume="">
                                <Defect title="Выбранные дефекты изделия" description="Выбранные оператором дефекты изделия" />
                            </Item>
                            <Item key="18" phosphor="" resume="">
                                <Defect title="Выбранные дефекты изделия" description="Выбранные оператором дефекты изделия" />
                            </Item>
                        </Slot>
                    </Settings>
                </Product>        5?      .??5?      ? .+?5?   
   2  ,DefectCheckControlLibrary.DefectCheckControl  -   5        $??control1??5?   %   $??Center=?5?   %   $??Center=?5?   %    5?   %   ??  ?? XPath$ Product??5?   %   5?      5?      